//===-- V850InstPrinter.cpp - Convert V850 MCInst to asm syntax -----------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This class prints a V850 MCInst to a .s file.
//
//===----------------------------------------------------------------------===//

#include "V850InstPrinter.h"
#include "V850MCTargetDesc.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

#define DEBUG_TYPE "asm-printer"

// Include the auto-generated portion of the assembly writer.
#define PRINT_ALIAS_INSTR
#include "V850GenAsmWriter.inc"

void V850InstPrinter::printRegName(raw_ostream &O, MCRegister Reg) {
  markup(O, Markup::Register) << getRegisterName(Reg);
}

void V850InstPrinter::printInst(const MCInst *MI, uint64_t Address,
                                StringRef Annot, const MCSubtargetInfo &STI,
                                raw_ostream &O) {
  printInstruction(MI, Address, STI, O);
  printAnnotation(O, Annot);
}

void V850InstPrinter::printOperand(const MCInst *MI, unsigned OpNo,
                                   const MCSubtargetInfo &STI, raw_ostream &O) {
  const MCOperand &MO = MI->getOperand(OpNo);

  if (MO.isReg()) {
    printRegName(O, MO.getReg());
    return;
  }

  if (MO.isImm()) {
    O << MO.getImm();
    return;
  }

  assert(MO.isExpr() && "Unknown operand kind in printOperand");
  MAI.printExpr(O, *MO.getExpr());
}

void V850InstPrinter::printCondCode(const MCInst *MI, unsigned OpNo,
                                    const MCSubtargetInfo &STI,
                                    raw_ostream &O) {
  const MCOperand &MO = MI->getOperand(OpNo);
  unsigned CC = MO.getImm() & 0xF;

  static const char *CondNames[] = {
      "v",  // 0000 - Overflow
      "c",  // 0001 - Carry/Lower
      "z",  // 0010 - Zero/Equal
      "nh", // 0011 - Not higher
      "n",  // 0100 - Negative
      "t",  // 0101 - Always (BR)
      "lt", // 0110 - Less than
      "le", // 0111 - Less or equal
      "nv", // 1000 - No overflow
      "nc", // 1001 - No carry/Not lower
      "nz", // 1010 - Not zero/Not equal
      "h",  // 1011 - Higher
      "p",  // 1100 - Positive
      "sa", // 1101 - Saturated
      "ge", // 1110 - Greater or equal
      "gt"  // 1111 - Greater than
  };

  O << CondNames[CC];
}

void V850InstPrinter::printMemDisp16(const MCInst *MI, unsigned OpNo,
                                     const MCSubtargetInfo &STI,
                                     raw_ostream &O) {
  // Memory operand is stored as two operands: reg1 (base) and disp16
  const MCOperand &BaseReg = MI->getOperand(OpNo);
  const MCOperand &Disp = MI->getOperand(OpNo + 1);

  // Print as disp16[reg1]
  if (Disp.isImm()) {
    O << Disp.getImm();
  } else if (Disp.isExpr()) {
    MAI.printExpr(O, *Disp.getExpr());
  }
  O << "[";
  printRegName(O, BaseReg.getReg());
  O << "]";
}

void V850InstPrinter::printDisp7EP(const MCInst *MI, unsigned OpNo,
                                   const MCSubtargetInfo &STI, raw_ostream &O) {
  // Short load/store displacement - printed as "disp[ep]"
  const MCOperand &Disp = MI->getOperand(OpNo);

  if (Disp.isImm()) {
    O << Disp.getImm();
  } else if (Disp.isExpr()) {
    MAI.printExpr(O, *Disp.getExpr());
  }
  O << "[ep]";
}

void V850InstPrinter::printDisp4EP(const MCInst *MI, unsigned OpNo,
                                   const MCSubtargetInfo &STI, raw_ostream &O) {
  // SLD.BU 4-bit displacement - printed as "disp[ep]"
  const MCOperand &Disp = MI->getOperand(OpNo);

  if (Disp.isImm()) {
    O << Disp.getImm();
  } else if (Disp.isExpr()) {
    MAI.printExpr(O, *Disp.getExpr());
  }
  O << "[ep]";
}

void V850InstPrinter::printDisp5EP(const MCInst *MI, unsigned OpNo,
                                   const MCSubtargetInfo &STI, raw_ostream &O) {
  // SLD.HU 5-bit displacement - printed as "disp[ep]"
  const MCOperand &Disp = MI->getOperand(OpNo);

  if (Disp.isImm()) {
    O << Disp.getImm();
  } else if (Disp.isExpr()) {
    MAI.printExpr(O, *Disp.getExpr());
  }
  O << "[ep]";
}
