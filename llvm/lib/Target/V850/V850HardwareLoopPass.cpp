//===-- V850HardwareLoopPass.cpp - Convert patterns to LOOP instruction ---===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This pass converts the 3-instruction pattern:
//
//   add  -1, reg      ; decrement counter
//   ...               ; other instructions (must not redefine reg)
//   cmp  0, reg       ; re-establish Z flag
//   bnz  target       ; branch if counter != 0
//
// into a single LOOP instruction:
//
//   loop reg, target   ; atomically decrement, set flags, branch if != 0
//
// The LOOP instruction is available on RH850G3M+ and combines the decrement,
// flag update, and backward branch into one 32-bit instruction.
//
// Prerequisites:
// - The HardwareLoops IR pass converts counted loops to start_loop_iterations
//   / loop_decrement_reg intrinsics.
// - ISel lowers loop_decrement_reg to SUB (which becomes ADD -1).
// - This pass runs pre-emit to catch the resulting machine code pattern.
//
//===----------------------------------------------------------------------===//

#include "V850.h"
#include "V850InstrInfo.h"
#include "V850Subtarget.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"

using namespace llvm;

#define DEBUG_TYPE "v850-hardware-loop"

STATISTIC(NumLoopsConverted,
          "Number of add/cmp/bnz patterns converted to LOOP");

static cl::opt<bool>
    DisableV850HWLoop("disable-v850-hw-loop", cl::Hidden,
                      cl::desc("Disable V850 Hardware Loop conversion"),
                      cl::init(false));

namespace {

class V850HardwareLoopPass : public MachineFunctionPass {
  const V850InstrInfo *TII = nullptr;
  const V850Subtarget *STI = nullptr;

public:
  static char ID;

  V850HardwareLoopPass() : MachineFunctionPass(ID) {}

  StringRef getPassName() const override {
    return "V850 Hardware Loop Conversion";
  }

  bool runOnMachineFunction(MachineFunction &MF) override;

  void getAnalysisUsage(AnalysisUsage &AU) const override {
    AU.setPreservesCFG();
    MachineFunctionPass::getAnalysisUsage(AU);
  }

private:
  bool convertBlock(MachineBasicBlock &MBB);

  /// Check if an opcode is a BNZ conditional branch (9-bit or 17-bit form).
  static bool isBNZ(unsigned Opc) {
    return Opc == V850::BNZ || Opc == V850::BNZ_17;
  }
};

} // end anonymous namespace

char V850HardwareLoopPass::ID = 0;

INITIALIZE_PASS(V850HardwareLoopPass, DEBUG_TYPE,
                "V850 Hardware Loop Conversion", false, false)

FunctionPass *llvm::createV850HardwareLoopPass() {
  return new V850HardwareLoopPass();
}

bool V850HardwareLoopPass::runOnMachineFunction(MachineFunction &MF) {
  if (skipFunction(MF.getFunction()))
    return false;

  if (DisableV850HWLoop)
    return false;

  STI = &MF.getSubtarget<V850Subtarget>();

  // LOOP instruction is only available on RH850G3M+
  if (!STI->hasRH850G3M())
    return false;

  TII = static_cast<const V850InstrInfo *>(STI->getInstrInfo());

  bool Changed = false;
  for (MachineBasicBlock &MBB : MF)
    Changed |= convertBlock(MBB);

  return Changed;
}

bool V850HardwareLoopPass::convertBlock(MachineBasicBlock &MBB) {
  // We need at least 3 instructions: ADD, CMP, BNZ
  if (MBB.size() < 3)
    return false;

  // Find the block terminator sequence: CMP 0, reg + BNZ target
  // Start from the end and skip debug instructions.
  auto I = MBB.end();

  // Find BNZ instruction (last terminator)
  MachineInstr *BNZInst = nullptr;
  while (I != MBB.begin()) {
    --I;
    if (I->isDebugInstr())
      continue;
    if (!I->isTerminator())
      return false;
    if (isBNZ(I->getOpcode())) {
      BNZInst = &*I;
      break;
    }
    // If the last terminator is not BNZ, this block doesn't match.
    return false;
  }

  if (!BNZInst)
    return false;

  // BNZ operand is the branch target
  MachineOperand &BrTarget = BNZInst->getOperand(0);
  if (!BrTarget.isMBB())
    return false;

  MachineBasicBlock *TargetMBB = BrTarget.getMBB();

  // Target must be a backward branch (target is a predecessor of this block,
  // or target is this block itself for single-block loops)
  bool IsBackward = false;
  for (MachineBasicBlock *Pred : MBB.predecessors()) {
    if (Pred == TargetMBB) {
      IsBackward = true;
      break;
    }
  }
  // Also handle self-loops (MBB branches back to itself)
  if (TargetMBB == &MBB)
    IsBackward = true;
  // Also handle the case where TargetMBB is the loop header and MBB is the
  // latch - TargetMBB is a successor of MBB (which is what BNZ targets)
  // and MBB is a predecessor of TargetMBB.
  if (!IsBackward) {
    for (MachineBasicBlock *Succ : MBB.successors()) {
      if (Succ == TargetMBB) {
        // Check if this is a backward edge by comparing block numbers
        // (TargetMBB should come before MBB in layout)
        if (TargetMBB->getNumber() <= MBB.getNumber()) {
          IsBackward = true;
          break;
        }
      }
    }
  }

  if (!IsBackward) {
    LLVM_DEBUG(dbgs() << "V850 HW Loop: BNZ target is not a backward branch, "
                         "skipping\n");
    return false;
  }

  // Find CMP 0, reg immediately before BNZ (skip debug instrs)
  MachineInstr *CMPInst = nullptr;
  auto CMPIter = I;
  while (CMPIter != MBB.begin()) {
    --CMPIter;
    if (CMPIter->isDebugInstr())
      continue;
    if (CMPIter->getOpcode() == V850::CMPi) {
      CMPInst = &*CMPIter;
      break;
    }
    // If we hit a non-debug, non-CMP instruction, the pattern doesn't match.
    return false;
  }

  if (!CMPInst)
    return false;

  // CMPi operands: reg2, imm5
  // Check that immediate is 0
  const MachineOperand &CMPImm = CMPInst->getOperand(1);
  if (!CMPImm.isImm() || CMPImm.getImm() != 0)
    return false;

  // Get the register being compared
  const MachineOperand &CMPReg = CMPInst->getOperand(0);
  if (!CMPReg.isReg())
    return false;

  Register LoopReg = CMPReg.getReg();

  // Scan backward from CMP to find ADD -1, reg (same register)
  MachineInstr *ADDInst = nullptr;
  auto ScanIter = CMPIter;
  while (ScanIter != MBB.begin()) {
    --ScanIter;
    if (ScanIter->isDebugInstr())
      continue;

    MachineInstr &MI = *ScanIter;

    // Check if this instruction defines LoopReg
    if (MI.getOpcode() == V850::ADDi) {
      // ADDi operands: (outs GPR:$reg2), (ins simm5:$imm5, GPR:$rs)
      // With constraint $rs = $reg2
      const MachineOperand &ADDDst = MI.getOperand(0);
      const MachineOperand &ADDImm = MI.getOperand(1);
      const MachineOperand &ADDSrc = MI.getOperand(2);

      if (ADDDst.isReg() && ADDDst.getReg() == LoopReg && ADDImm.isImm() &&
          ADDImm.getImm() == -1 && ADDSrc.isReg() &&
          ADDSrc.getReg() == LoopReg) {
        ADDInst = &MI;
        break;
      }
    }

    // Check if this instruction defines LoopReg (kills our pattern)
    for (const MachineOperand &MO : MI.operands()) {
      if (MO.isReg() && MO.isDef() && MO.getReg() == LoopReg) {
        LLVM_DEBUG(dbgs() << "V850 HW Loop: LoopReg redefined before ADD -1, "
                             "skipping\n");
        return false;
      }
    }
  }

  if (!ADDInst) {
    LLVM_DEBUG(dbgs() << "V850 HW Loop: ADD -1 not found for reg, skipping\n");
    return false;
  }

  // Also check that LoopReg is not redefined between ADD and CMP
  // (we already checked this in the scan above, since we break on any def)

  LLVM_DEBUG(dbgs() << "V850 HW Loop: Converting ADD -1 + CMP 0 + BNZ to "
                       "LOOP in "
                    << MBB.getName() << "\n");

  // Build the LOOP instruction.
  // LOOP: (outs GPR:$reg1_out), (ins GPR:$reg1, brtarget16:$disp16)
  // The tied constraint "$reg1_out = $reg1" means LOOP atomically decrements
  // reg1 and branches.
  BuildMI(MBB, BNZInst, BNZInst->getDebugLoc(), TII->get(V850::LOOP), LoopReg)
      .addReg(LoopReg)
      .addMBB(TargetMBB);

  // Remove the three original instructions
  BNZInst->eraseFromParent();
  CMPInst->eraseFromParent();
  ADDInst->eraseFromParent();

  ++NumLoopsConverted;
  return true;
}
