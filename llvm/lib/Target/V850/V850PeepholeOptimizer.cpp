//===-- V850PeepholeOptimizer.cpp - V850 Peephole Optimizations -----------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This pass performs peephole optimizations on V850 machine code:
//
// 1. MOV r0, rX + ADD imm, rX -> MOV imm, rX
//    When loading zero and then adding a small immediate, use MOV immediate.
//
// 2. Redundant ANDI after zero-extending load
//    LDBU already zero-extends, so ANDI 0xFF is redundant.
//    LDHU already zero-extends, so ANDI 0xFFFF is redundant.
//
// 3. Copy propagation for consecutive MOV instructions
//    MOV rA, rB + MOV rB, rC -> MOV rA, rC (when rB has single use)
//
//===----------------------------------------------------------------------===//

#include "V850.h"
#include "V850InstrInfo.h"
#include "V850Subtarget.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/TargetInstrInfo.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"

using namespace llvm;

#define DEBUG_TYPE "v850-peephole"

STATISTIC(NumMovAddFolded, "Number of MOV+ADD pairs folded to MOV imm");
STATISTIC(NumRedundantAndiRemoved,
          "Number of redundant ANDI removed after load");
STATISTIC(NumCopyPropagated, "Number of MOV copy propagations");

static cl::opt<bool>
    DisableV850Peephole("disable-v850-peephole", cl::Hidden,
                        cl::desc("Disable V850 Peephole Optimization"),
                        cl::init(false));

namespace {

class V850PeepholeOptimizer : public MachineFunctionPass {
  const V850InstrInfo *TII = nullptr;
  MachineRegisterInfo *MRI = nullptr;

public:
  static char ID;

  V850PeepholeOptimizer() : MachineFunctionPass(ID) {}

  StringRef getPassName() const override { return "V850 Peephole Optimizer"; }

  bool runOnMachineFunction(MachineFunction &MF) override;

  void getAnalysisUsage(AnalysisUsage &AU) const override {
    AU.setPreservesCFG();
    MachineFunctionPass::getAnalysisUsage(AU);
  }

private:
  bool optimizeBlock(MachineBasicBlock &MBB);
  bool tryFoldMovAddToMovImm(MachineBasicBlock &MBB,
                             MachineBasicBlock::iterator &MBBI);
  bool tryRemoveRedundantAndi(MachineBasicBlock &MBB,
                              MachineBasicBlock::iterator &MBBI);
  bool tryCopyPropagation(MachineBasicBlock &MBB,
                          MachineBasicBlock::iterator &MBBI);
};

} // end anonymous namespace

char V850PeepholeOptimizer::ID = 0;

INITIALIZE_PASS(V850PeepholeOptimizer, DEBUG_TYPE, "V850 Peephole Optimizer",
                false, false)

FunctionPass *llvm::createV850PeepholeOptimizerPass() {
  return new V850PeepholeOptimizer();
}

bool V850PeepholeOptimizer::runOnMachineFunction(MachineFunction &MF) {
  if (skipFunction(MF.getFunction()))
    return false;

  if (DisableV850Peephole)
    return false;

  TII = static_cast<const V850InstrInfo *>(MF.getSubtarget().getInstrInfo());
  MRI = &MF.getRegInfo();

  bool Changed = false;
  for (MachineBasicBlock &MBB : MF)
    Changed |= optimizeBlock(MBB);

  return Changed;
}

bool V850PeepholeOptimizer::optimizeBlock(MachineBasicBlock &MBB) {
  bool Changed = false;

  for (MachineBasicBlock::iterator MBBI = MBB.begin(), E = MBB.end();
       MBBI != E;) {
    MachineBasicBlock::iterator Current = MBBI++;

    // Try various peephole optimizations
    if (tryFoldMovAddToMovImm(MBB, Current)) {
      Changed = true;
      continue;
    }

    if (tryRemoveRedundantAndi(MBB, Current)) {
      Changed = true;
      continue;
    }

    if (tryCopyPropagation(MBB, Current)) {
      Changed = true;
      continue;
    }
  }

  return Changed;
}

/// Try to fold MOV r0, rX + ADD imm, rX -> MOV imm, rX
/// This pattern occurs when loading zero and then adding a constant.
bool V850PeepholeOptimizer::tryFoldMovAddToMovImm(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator &MBBI) {
  MachineInstr &MI = *MBBI;

  // Look for MOV r0, rX (which is encoded as MOV with R0 source)
  if (MI.getOpcode() != V850::MOV)
    return false;

  // Check if source is R0
  const MachineOperand &Src = MI.getOperand(1);
  if (!Src.isReg() || Src.getReg() != V850::R0)
    return false;

  const MachineOperand &Dst = MI.getOperand(0);
  if (!Dst.isReg() || !Dst.getReg().isVirtual())
    return false;

  Register DstReg = Dst.getReg();

  // Check if there's exactly one use
  if (!MRI->hasOneUse(DstReg))
    return false;

  // Find the single use
  MachineInstr *UseInstr = &*MRI->use_instr_begin(DstReg);

  // Check if it's an ADD with immediate (ADDi instruction)
  if (UseInstr->getOpcode() != V850::ADDi)
    return false;

  // ADDi operands: dst, imm5, src (rs)
  // Check if the ADD uses DstReg as source and writes to the same register
  const MachineOperand &AddDst = UseInstr->getOperand(0);
  const MachineOperand &AddImm = UseInstr->getOperand(1);
  const MachineOperand &AddSrc = UseInstr->getOperand(2);

  if (!AddSrc.isReg() || AddSrc.getReg() != DstReg)
    return false;

  if (!AddImm.isImm())
    return false;

  int64_t Imm = AddImm.getImm();

  // Check if immediate fits in MOVi (5-bit signed: -16 to 15)
  if (Imm < -16 || Imm > 15)
    return false;

  Register ResultReg = AddDst.getReg();

  LLVM_DEBUG(dbgs() << "V850 Peephole: Folding MOV r0 + ADD " << Imm
                    << " to MOV " << Imm << "\n");

  // Create new MOVi instruction
  BuildMI(MBB, UseInstr, UseInstr->getDebugLoc(), TII->get(V850::MOVi),
          ResultReg)
      .addImm(Imm);

  // Remove both original instructions
  UseInstr->eraseFromParent();
  MI.eraseFromParent();

  ++NumMovAddFolded;
  return true;
}

/// Try to remove redundant ANDI after zero-extending loads.
/// LDBU produces zero-extended result, so ANDI 0xFF is redundant.
/// LDHU produces zero-extended result, so ANDI 0xFFFF is redundant.
bool V850PeepholeOptimizer::tryRemoveRedundantAndi(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator &MBBI) {
  MachineInstr &MI = *MBBI;

  // Look for ANDI instruction
  if (MI.getOpcode() != V850::ANDI)
    return false;

  // ANDI operands: dst, src, imm16
  const MachineOperand &Dst = MI.getOperand(0);
  const MachineOperand &Src = MI.getOperand(1);
  const MachineOperand &Mask = MI.getOperand(2);

  if (!Src.isReg() || !Src.getReg().isVirtual())
    return false;

  if (!Mask.isImm())
    return false;

  int64_t MaskVal = Mask.getImm();

  // Only handle 0xFF and 0xFFFF masks
  if (MaskVal != 0xFF && MaskVal != 0xFFFF)
    return false;

  Register SrcReg = Src.getReg();

  // Find the definition of the source register
  MachineInstr *DefInstr = MRI->getVRegDef(SrcReg);
  if (!DefInstr)
    return false;

  // Check if it's a zero-extending load
  bool IsRedundant = false;
  if (MaskVal == 0xFF) {
    // LDBU already zero-extends byte to 32 bits
    IsRedundant = (DefInstr->getOpcode() == V850::LDBU);
  } else if (MaskVal == 0xFFFF) {
    // LDHU already zero-extends halfword to 32 bits
    IsRedundant = (DefInstr->getOpcode() == V850::LDHU);
  }

  if (!IsRedundant)
    return false;

  LLVM_DEBUG(dbgs() << "V850 Peephole: Removing redundant ANDI after "
                    << (MaskVal == 0xFF ? "LDBU" : "LDHU") << "\n");

  // Replace all uses of ANDI result with the source register
  Register DstReg = Dst.getReg();
  MRI->replaceRegWith(DstReg, SrcReg);

  // Remove the ANDI instruction
  MI.eraseFromParent();

  ++NumRedundantAndiRemoved;
  return true;
}

/// Try copy propagation for consecutive MOV instructions.
/// MOV rA, rB followed by MOV rB, rC (where rB has single use) -> MOV rA, rC
bool V850PeepholeOptimizer::tryCopyPropagation(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator &MBBI) {
  MachineInstr &MI = *MBBI;

  // Look for MOV instruction (reg to reg)
  if (MI.getOpcode() != V850::MOV)
    return false;

  const MachineOperand &Dst = MI.getOperand(0);
  const MachineOperand &Src = MI.getOperand(1);

  if (!Dst.isReg() || !Dst.getReg().isVirtual())
    return false;

  if (!Src.isReg() || !Src.getReg().isVirtual())
    return false;

  Register DstReg = Dst.getReg();
  Register SrcReg = Src.getReg();

  // Check if DstReg has exactly one use
  if (!MRI->hasOneUse(DstReg))
    return false;

  // Find the single use
  MachineInstr *UseInstr = &*MRI->use_instr_begin(DstReg);

  // Check if it's another MOV instruction
  if (UseInstr->getOpcode() != V850::MOV)
    return false;

  const MachineOperand &UseSrc = UseInstr->getOperand(1);
  if (!UseSrc.isReg() || UseSrc.getReg() != DstReg)
    return false;

  LLVM_DEBUG(dbgs() << "V850 Peephole: Copy propagation MOV chain\n");

  // Update the second MOV to use the original source
  MachineOperand &UseSrcMO = UseInstr->getOperand(1);
  UseSrcMO.setReg(SrcReg);

  // Remove the first MOV
  MI.eraseFromParent();

  ++NumCopyPropagated;
  return true;
}
