//===-- V850LoadStoreOptimizer.cpp - V850 Load/Store Optimization ---------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains a pass that performs load/store optimizations for V850.
//
// Optimizations performed:
// 1. Short format promotion: Convert 32-bit LD.W/ST.W to 16-bit SLD.W/SST.W
//    when the base register is EP and displacement fits in 7 bits.
//
// Note: The V850 architecture does not have double-word (64-bit) load/store
// instructions. The FPU uses register pairs with separate 32-bit operations.
//
//===----------------------------------------------------------------------===//

#include "V850.h"
#include "V850InstrInfo.h"
#include "V850Subtarget.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/TargetRegisterInfo.h"
#include "llvm/Support/Debug.h"

using namespace llvm;

#define DEBUG_TYPE "v850-load-store-opt"
#define PASS_NAME "V850 Load/Store Optimizer"

namespace {

class V850LoadStoreOptimizer : public MachineFunctionPass {
public:
  static char ID;

  V850LoadStoreOptimizer() : MachineFunctionPass(ID) {}

  bool runOnMachineFunction(MachineFunction &MF) override;

  StringRef getPassName() const override { return PASS_NAME; }

private:
  const V850InstrInfo *TII = nullptr;
  const TargetRegisterInfo *TRI = nullptr;
  const V850Subtarget *STI = nullptr;

  /// Try to promote a 32-bit load to 16-bit short format.
  bool tryPromoteToShortLoad(MachineInstr &MI);

  /// Try to promote a 32-bit store to 16-bit short format.
  bool tryPromoteToShortStore(MachineInstr &MI);

  /// Check if the given register is EP (Element Pointer).
  bool isEP(Register Reg) const { return Reg == V850::EP; }

  /// Check if displacement fits in 7 bits for word access (must be 4-byte aligned).
  bool isShortWordDisp(int64_t Disp) const {
    // SLD.W/SST.W use a 7-bit word-aligned displacement (bits 7:1, scaled by 4)
    // Range: 0 to 508 (0 to 127 * 4)
    return Disp >= 0 && Disp <= 508 && (Disp & 3) == 0;
  }
};

} // end anonymous namespace

char V850LoadStoreOptimizer::ID = 0;

INITIALIZE_PASS(V850LoadStoreOptimizer, DEBUG_TYPE, PASS_NAME, false, false)

bool V850LoadStoreOptimizer::runOnMachineFunction(MachineFunction &MF) {
  STI = &MF.getSubtarget<V850Subtarget>();
  TII = STI->getInstrInfo();
  TRI = STI->getRegisterInfo();

  // Short format instructions require V850E1 or later
  if (!STI->hasV850E1())
    return false;

  bool Changed = false;

  for (MachineBasicBlock &MBB : MF) {
    for (MachineInstr &MI : llvm::make_early_inc_range(MBB)) {
      switch (MI.getOpcode()) {
      case V850::LDW:
        Changed |= tryPromoteToShortLoad(MI);
        break;
      case V850::STW:
        Changed |= tryPromoteToShortStore(MI);
        break;
      default:
        break;
      }
    }
  }

  return Changed;
}

bool V850LoadStoreOptimizer::tryPromoteToShortLoad(MachineInstr &MI) {
  // LDW format: LDW reg2, disp16[reg1]
  // Operands: reg2 (def), reg1 (base), disp16
  assert(MI.getOpcode() == V850::LDW);

  if (MI.getNumOperands() < 3)
    return false;

  Register DestReg = MI.getOperand(0).getReg();
  Register BaseReg = MI.getOperand(1).getReg();
  MachineOperand &DispOp = MI.getOperand(2);

  // Must use EP as base register
  if (!isEP(BaseReg))
    return false;

  // Displacement must be an immediate
  if (!DispOp.isImm())
    return false;

  int64_t Disp = DispOp.getImm();

  // Check if displacement fits in short format
  if (!isShortWordDisp(Disp))
    return false;

  // Encode displacement for SLD.W: divide by 4 to get the 7-bit field
  unsigned ShortDisp = Disp;

  LLVM_DEBUG(dbgs() << "Promoting LDW to SLDW: " << MI);

  // Build the short load instruction
  MachineBasicBlock *MBB = MI.getParent();
  DebugLoc DL = MI.getDebugLoc();

  BuildMI(*MBB, MI, DL, TII->get(V850::SLDW), DestReg)
      .addImm(ShortDisp);

  // Remove the original instruction
  MI.eraseFromParent();

  return true;
}

bool V850LoadStoreOptimizer::tryPromoteToShortStore(MachineInstr &MI) {
  // STW format: STW reg2, disp16[reg1]
  // Operands: reg2 (src), reg1 (base), disp16
  assert(MI.getOpcode() == V850::STW);

  if (MI.getNumOperands() < 3)
    return false;

  Register SrcReg = MI.getOperand(0).getReg();
  Register BaseReg = MI.getOperand(1).getReg();
  MachineOperand &DispOp = MI.getOperand(2);

  // Must use EP as base register
  if (!isEP(BaseReg))
    return false;

  // Displacement must be an immediate
  if (!DispOp.isImm())
    return false;

  int64_t Disp = DispOp.getImm();

  // Check if displacement fits in short format
  if (!isShortWordDisp(Disp))
    return false;

  // Encode displacement for SST.W: divide by 4 to get the 7-bit field
  unsigned ShortDisp = Disp;

  LLVM_DEBUG(dbgs() << "Promoting STW to SSTW: " << MI);

  // Build the short store instruction
  MachineBasicBlock *MBB = MI.getParent();
  DebugLoc DL = MI.getDebugLoc();

  BuildMI(*MBB, MI, DL, TII->get(V850::SSTW))
      .addReg(SrcReg)
      .addImm(ShortDisp);

  // Remove the original instruction
  MI.eraseFromParent();

  return true;
}

FunctionPass *llvm::createV850LoadStoreOptimizerPass() {
  return new V850LoadStoreOptimizer();
}
