//===-- V850AsmPrinter.cpp - V850 LLVM assembly writer --------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains a printer that converts from our internal representation
// of machine-dependent LLVM code to the V850 assembly language.
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/V850InstPrinter.h"
#include "V850.h"
#include "V850MCInstLower.h"
#include "V850TargetMachine.h"
#include "TargetInfo/V850TargetInfo.h"
#include "llvm/BinaryFormat/ELF.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/CodeGen/MachineConstantPool.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/CodeGen/MachineJumpTableInfo.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/IR/Mangler.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCSectionELF.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Compiler.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

#define DEBUG_TYPE "asm-printer"

namespace {
class V850AsmPrinter : public AsmPrinter {
public:
  V850AsmPrinter(TargetMachine &TM, std::unique_ptr<MCStreamer> Streamer)
      : AsmPrinter(TM, std::move(Streamer), ID) {}

  StringRef getPassName() const override { return "V850 Assembly Printer"; }

  bool runOnMachineFunction(MachineFunction &MF) override;

  void PrintSymbolOperand(const MachineOperand &MO, raw_ostream &O) override;
  void printOperand(const MachineInstr *MI, int OpNum, raw_ostream &O);
  bool PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                       const char *ExtraCode, raw_ostream &O) override;
  bool PrintAsmMemoryOperand(const MachineInstr *MI, unsigned OpNo,
                             const char *ExtraCode, raw_ostream &O) override;
  void emitInstruction(const MachineInstr *MI) override;

  static char ID;
};
} // end of anonymous namespace

void V850AsmPrinter::PrintSymbolOperand(const MachineOperand &MO,
                                         raw_ostream &O) {
  uint64_t Offset = MO.getOffset();
  if (Offset)
    O << '(' << Offset << '+';

  getSymbol(MO.getGlobal())->print(O, MAI);

  if (Offset)
    O << ')';
}

void V850AsmPrinter::printOperand(const MachineInstr *MI, int OpNum,
                                   raw_ostream &O) {
  const MachineOperand &MO = MI->getOperand(OpNum);
  switch (MO.getType()) {
  default:
    llvm_unreachable("Not implemented yet!");
  case MachineOperand::MO_Register:
    O << V850InstPrinter::getRegisterName(MO.getReg());
    return;
  case MachineOperand::MO_Immediate:
    O << MO.getImm();
    return;
  case MachineOperand::MO_MachineBasicBlock:
    MO.getMBB()->getSymbol()->print(O, MAI);
    return;
  case MachineOperand::MO_GlobalAddress:
    PrintSymbolOperand(MO, O);
    return;
  }
}

bool V850AsmPrinter::PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                                      const char *ExtraCode, raw_ostream &O) {
  if (ExtraCode && ExtraCode[0])
    return AsmPrinter::PrintAsmOperand(MI, OpNo, ExtraCode, O);

  printOperand(MI, OpNo, O);
  return false;
}

bool V850AsmPrinter::PrintAsmMemoryOperand(const MachineInstr *MI,
                                            unsigned OpNo,
                                            const char *ExtraCode,
                                            raw_ostream &O) {
  if (ExtraCode && ExtraCode[0])
    return true; // Unknown modifier.

  // V850 memory operand format: disp[base]
  printOperand(MI, OpNo + 1, O);
  O << '[';
  printOperand(MI, OpNo, O);
  O << ']';
  return false;
}

void V850AsmPrinter::emitInstruction(const MachineInstr *MI) {
  V850_MC::verifyInstructionPredicates(MI->getOpcode(),
                                        getSubtargetInfo().getFeatureBits());

  // Handle pseudo-instructions that need expansion
  switch (MI->getOpcode()) {
  case V850::RET: {
    // RET pseudo expands to: jmp [lp]
    MCInst JmpInst;
    JmpInst.setOpcode(V850::JMP);
    JmpInst.addOperand(MCOperand::createReg(V850::LP));
    EmitToStreamer(*OutStreamer, JmpInst);
    return;
  }
  case V850::SWITCH_JT: {
    // SWITCH_JT pseudo expands to: switch reg + inline jump table
    // Emit the SWITCH instruction
    MCInst SwitchInst;
    SwitchInst.setOpcode(V850::SWITCH);
    SwitchInst.addOperand(MCOperand::createReg(MI->getOperand(0).getReg()));
    EmitToStreamer(*OutStreamer, SwitchInst);

    // Emit the inline jump table
    // Each entry is a signed 16-bit offset from the table base
    unsigned JTI = MI->getOperand(1).getIndex();
    const MachineJumpTableInfo *MJTI = MF->getJumpTableInfo();
    const std::vector<MachineJumpTableEntry> &JT = MJTI->getJumpTables();
    const std::vector<MachineBasicBlock *> &JTBBs = JT[JTI].MBBs;

    // Create a symbol for the jump table base (immediately after SWITCH)
    MCSymbol *JTISymbol = GetJTISymbol(JTI);
    OutStreamer->emitLabel(JTISymbol);

    // Emit each jump table entry as a .hword offset
    for (MachineBasicBlock *MBB : JTBBs) {
      // Entry = (target - table_base) >> 1
      // But since we're emitting .hword with a subtraction expression,
      // the assembler will compute the difference
      const MCExpr *Value = MCSymbolRefExpr::create(MBB->getSymbol(), OutContext);
      const MCExpr *Base = MCSymbolRefExpr::create(JTISymbol, OutContext);
      const MCExpr *Diff = MCBinaryExpr::createSub(Value, Base, OutContext);
      // Shift right by 1 (divide by 2) since SWITCH multiplies by 2
      const MCExpr *ShiftedDiff = MCBinaryExpr::createAShr(
          Diff, MCConstantExpr::create(1, OutContext), OutContext);
      OutStreamer->emitValue(ShiftedDiff, 2); // 2 bytes = halfword
    }
    return;
  }
  default:
    break;
  }

  V850MCInstLower MCInstLowering(OutContext, *this);

  MCInst TmpInst;
  MCInstLowering.Lower(MI, TmpInst);
  EmitToStreamer(*OutStreamer, TmpInst);
}

bool V850AsmPrinter::runOnMachineFunction(MachineFunction &MF) {
  SetupMachineFunction(MF);
  emitFunctionBody();
  return false;
}

char V850AsmPrinter::ID = 0;

INITIALIZE_PASS(V850AsmPrinter, "v850-asm-printer", "V850 Assembly Printer",
                false, false)

// Force static initialization.
extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void LLVMInitializeV850AsmPrinter() {
  RegisterAsmPrinter<V850AsmPrinter> X(getTheV850Target());
}
