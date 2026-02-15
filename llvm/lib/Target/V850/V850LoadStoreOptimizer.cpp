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
// 2. Double-word merge: Merge adjacent LD.W/ST.W pairs into LD.DW/ST.DW
//    (RH850G3M+) when they access consecutive addresses with an even-odd
//    register pair.
//
//===----------------------------------------------------------------------===//

#include "V850.h"
#include "V850InstrInfo.h"
#include "V850Subtarget.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/TargetRegisterInfo.h"
#include "llvm/Support/Debug.h"

using namespace llvm;

#define DEBUG_TYPE "v850-load-store-opt"
#define PASS_NAME "V850 Load/Store Optimizer"

STATISTIC(NumLoadsPromoted, "Number of loads promoted to short format");
STATISTIC(NumStoresPromoted, "Number of stores promoted to short format");
STATISTIC(NumLoadsMerged, "Number of load pairs merged to LD.DW");
STATISTIC(NumStoresMerged, "Number of store pairs merged to ST.DW");

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

  /// Try to merge adjacent LD.W pair into LD.DW.
  bool tryMergeLoadPair(MachineBasicBlock &MBB);

  /// Try to merge adjacent ST.W pair into ST.DW.
  bool tryMergeStorePair(MachineBasicBlock &MBB);

  /// Check if the given register is EP (Element Pointer).
  bool isEP(Register Reg) const { return Reg == V850::EP; }

  /// Check if displacement fits in 7 bits for word access (must be 4-byte
  /// aligned).
  bool isShortWordDisp(int64_t Disp) const {
    // SLD.W/SST.W use a 7-bit word-aligned displacement (bits 7:1, scaled by
    // 4) Range: 0 to 508 (0 to 127 * 4)
    return Disp >= 0 && Disp <= 508 && (Disp & 3) == 0;
  }

  /// Get the hardware encoding of a register.
  unsigned getRegEncoding(Register Reg) const {
    return TRI->getEncodingValue(Reg);
  }

  /// Check if a register has an even hardware encoding.
  bool isEvenReg(Register Reg) const { return (getRegEncoding(Reg) & 1) == 0; }

  /// Get the register with encoding Enc+1 (odd partner of an even register).
  Register getOddPartner(Register EvenReg) const;

  /// Check if displacement fits in simm23 (23-bit signed).
  bool isSimm23(int64_t Disp) const {
    return Disp >= -(1 << 22) && Disp < (1 << 22);
  }

  /// Check if an instruction between two candidates could prevent merging.
  bool isHazardBetween(MachineInstr &First, MachineInstr &Second,
                       Register BaseReg, Register Reg1, Register Reg2) const;
};

} // end anonymous namespace

char V850LoadStoreOptimizer::ID = 0;

INITIALIZE_PASS(V850LoadStoreOptimizer, DEBUG_TYPE, PASS_NAME, false, false)

Register V850LoadStoreOptimizer::getOddPartner(Register EvenReg) const {
  unsigned Enc = getRegEncoding(EvenReg);
  assert((Enc & 1) == 0 && "Expected even register");
  unsigned OddEnc = Enc + 1;

  // Map encoding back to register.
  // V850 GPRs have sequential encodings 0-31.
  static const MCPhysReg GPRTable[] = {
      V850::R0,  V850::R1,  V850::R2,  V850::SP,  V850::GP,  V850::TP,
      V850::R6,  V850::R7,  V850::R8,  V850::R9,  V850::R10, V850::R11,
      V850::R12, V850::R13, V850::R14, V850::R15, V850::R16, V850::R17,
      V850::R18, V850::R19, V850::R20, V850::R21, V850::R22, V850::R23,
      V850::R24, V850::R25, V850::R26, V850::R27, V850::R28, V850::R29,
      V850::EP,  V850::LP};

  if (OddEnc < 32)
    return GPRTable[OddEnc];
  return Register();
}

bool V850LoadStoreOptimizer::isHazardBetween(MachineInstr &First,
                                             MachineInstr &Second,
                                             Register BaseReg, Register Reg1,
                                             Register Reg2) const {
  // Check all instructions between First and Second for hazards.
  for (auto It = std::next(First.getIterator()); It != Second.getIterator();
       ++It) {
    MachineInstr &MI = *It;

    // If any instruction modifies the base register, we can't merge.
    if (MI.modifiesRegister(BaseReg, TRI))
      return true;

    // For loads: if any instruction modifies either destination register,
    // we can't merge.
    if (MI.modifiesRegister(Reg1, TRI) || MI.modifiesRegister(Reg2, TRI))
      return true;

    // For stores: if any instruction reads from the store source registers
    // after they might have been modified, we need to be careful.
    // Actually for stores, we just need the base register to be stable
    // and the values to still be in registers. If something between them
    // modifies a store source, the merge would change behavior.

    // If any instruction is a call or has side effects that could affect
    // memory ordering, don't merge.
    if (MI.isCall() || MI.hasUnmodeledSideEffects())
      return true;
  }
  return false;
}

bool V850LoadStoreOptimizer::tryMergeLoadPair(MachineBasicBlock &MBB) {
  bool Changed = false;

  for (auto MBBI = MBB.begin(), MBBE = MBB.end(); MBBI != MBBE;) {
    MachineInstr &MI = *MBBI;
    if (MI.getOpcode() != V850::LDW) {
      ++MBBI;
      continue;
    }

    // Don't merge volatile or ordered memory accesses — the hardware may
    // handle individual word accesses differently from doubleword accesses
    // for MMIO/volatile regions.
    if (MI.hasOrderedMemoryRef()) {
      ++MBBI;
      continue;
    }

    // Found a LDW. Look for a partner within a small window.
    Register DestReg1 = MI.getOperand(0).getReg();
    Register BaseReg1 = MI.getOperand(1).getReg();
    if (!MI.getOperand(2).isImm()) {
      ++MBBI;
      continue;
    }
    int64_t Disp1 = MI.getOperand(2).getImm();

    // Search forward for a matching LDW (limited window).
    constexpr unsigned SearchWindow = 4;
    unsigned Count = 0;
    bool Merged = false;

    for (auto NextI = std::next(MBBI); NextI != MBBE && Count < SearchWindow;
         ++NextI, ++Count) {
      MachineInstr &NextMI = *NextI;
      if (NextMI.getOpcode() != V850::LDW)
        continue;

      // Skip volatile/ordered candidates too.
      if (NextMI.hasOrderedMemoryRef())
        continue;

      Register DestReg2 = NextMI.getOperand(0).getReg();
      Register BaseReg2 = NextMI.getOperand(1).getReg();
      if (!NextMI.getOperand(2).isImm())
        continue;
      int64_t Disp2 = NextMI.getOperand(2).getImm();

      // Must use the same base register.
      if (BaseReg1 != BaseReg2)
        continue;

      // Determine which is the lower and higher load.
      Register EvenReg, OddReg;
      int64_t LowDisp;
      MachineInstr *LowMI, *HighMI;

      if (Disp2 == Disp1 + 4) {
        // MI loads at lower address, NextMI at higher.
        LowDisp = Disp1;
        LowMI = &MI;
        HighMI = &NextMI;
        EvenReg = DestReg1;
        OddReg = DestReg2;
      } else if (Disp1 == Disp2 + 4) {
        // NextMI loads at lower address, MI at higher.
        LowDisp = Disp2;
        LowMI = &NextMI;
        HighMI = &MI;
        EvenReg = DestReg2;
        OddReg = DestReg1;
      } else {
        continue;
      }

      // Check that EvenReg has an even encoding and OddReg = EvenReg + 1.
      if (!isEvenReg(EvenReg))
        continue;
      Register ExpectedOdd = getOddPartner(EvenReg);
      if (!ExpectedOdd.isValid() || ExpectedOdd != OddReg)
        continue;

      // Don't use r0 as destination (writes ignored).
      if (EvenReg == V850::R0)
        continue;

      // Displacement must fit in simm23 and be word-aligned.
      if (!isSimm23(LowDisp) || (LowDisp & 3) != 0)
        continue;

      // Check for hazards between the two instructions.
      // Always use program order: MI comes before NextMI in the MBB.
      if (MI.getIterator() != std::prev(NextMI.getIterator())) {
        if (isHazardBetween(MI, NextMI, BaseReg1, EvenReg, OddReg))
          continue;
      }

      // Don't merge if the base register is one of the destination registers,
      // as LD.DW would clobber it before the second load.
      if (BaseReg1 == EvenReg || BaseReg1 == OddReg)
        continue;

      LLVM_DEBUG(dbgs() << "Merging load pair into LD.DW:\n"
                        << "  " << *LowMI << "  " << *HighMI);

      // Build the LD.DW instruction.
      // LD.DW loads reg3 (even) from [base+disp] and reg3+1 from [base+disp+4].
      DebugLoc DL = LowMI->getDebugLoc();
      auto MIB = BuildMI(MBB, *LowMI, DL, TII->get(V850::LD_DW), EvenReg)
                     .addReg(BaseReg1)
                     .addImm(LowDisp);
      // Add implicit-def for the odd register since LD_DW writes both.
      MIB.addReg(OddReg, RegState::ImplicitDefine);

      // Remove both original instructions.
      // Save the new instruction iterator before erasing.
      auto NewIt = MIB->getIterator();

      LowMI->eraseFromParent();
      HighMI->eraseFromParent();

      // Advance past the newly created LD.DW instruction.
      MBBI = std::next(NewIt);

      ++NumLoadsMerged;
      Changed = true;
      Merged = true;
      break;
    }

    if (!Merged)
      ++MBBI;
  }

  return Changed;
}

bool V850LoadStoreOptimizer::tryMergeStorePair(MachineBasicBlock &MBB) {
  bool Changed = false;

  for (auto MBBI = MBB.begin(), MBBE = MBB.end(); MBBI != MBBE;) {
    MachineInstr &MI = *MBBI;
    if (MI.getOpcode() != V850::STW) {
      ++MBBI;
      continue;
    }

    // Don't merge volatile or ordered memory accesses.
    if (MI.hasOrderedMemoryRef()) {
      ++MBBI;
      continue;
    }

    // Found a STW. Look for a partner.
    Register SrcReg1 = MI.getOperand(0).getReg();
    Register BaseReg1 = MI.getOperand(1).getReg();
    if (!MI.getOperand(2).isImm()) {
      ++MBBI;
      continue;
    }
    int64_t Disp1 = MI.getOperand(2).getImm();

    constexpr unsigned SearchWindow = 4;
    unsigned Count = 0;
    bool Merged = false;

    for (auto NextI = std::next(MBBI); NextI != MBBE && Count < SearchWindow;
         ++NextI, ++Count) {
      MachineInstr &NextMI = *NextI;
      if (NextMI.getOpcode() != V850::STW)
        continue;

      // Skip volatile/ordered candidates too.
      if (NextMI.hasOrderedMemoryRef())
        continue;

      Register SrcReg2 = NextMI.getOperand(0).getReg();
      Register BaseReg2 = NextMI.getOperand(1).getReg();
      if (!NextMI.getOperand(2).isImm())
        continue;
      int64_t Disp2 = NextMI.getOperand(2).getImm();

      if (BaseReg1 != BaseReg2)
        continue;

      // Determine which is the lower and higher store.
      Register EvenReg, OddReg;
      int64_t LowDisp;
      MachineInstr *LowMI, *HighMI;

      if (Disp2 == Disp1 + 4) {
        LowDisp = Disp1;
        LowMI = &MI;
        HighMI = &NextMI;
        EvenReg = SrcReg1;
        OddReg = SrcReg2;
      } else if (Disp1 == Disp2 + 4) {
        LowDisp = Disp2;
        LowMI = &NextMI;
        HighMI = &MI;
        EvenReg = SrcReg2;
        OddReg = SrcReg1;
      } else {
        continue;
      }

      // Check even-odd register pair requirement.
      if (!isEvenReg(EvenReg))
        continue;
      Register ExpectedOdd = getOddPartner(EvenReg);
      if (!ExpectedOdd.isValid() || ExpectedOdd != OddReg)
        continue;

      if (!isSimm23(LowDisp) || (LowDisp & 3) != 0)
        continue;

      // Check for hazards. Determine program order: MI comes before NextMI.
      MachineInstr &FirstMI = (LowMI == &MI) ? *LowMI : *HighMI;
      MachineInstr &SecondMI = (LowMI == &MI) ? *HighMI : *LowMI;
      if (&FirstMI != &SecondMI &&
          FirstMI.getIterator() != std::prev(SecondMI.getIterator())) {
        if (isHazardBetween(FirstMI, SecondMI, BaseReg1, EvenReg, OddReg))
          continue;
      }

      LLVM_DEBUG(dbgs() << "Merging store pair into ST.DW:\n"
                        << "  " << *LowMI << "  " << *HighMI);

      // Build the ST.DW instruction.
      // ST.DW stores reg3 (even) to [base+disp] and reg3+1 to [base+disp+4].
      DebugLoc DL = FirstMI.getDebugLoc();
      auto MIB = BuildMI(MBB, FirstMI, DL, TII->get(V850::ST_DW))
                     .addReg(EvenReg)
                     .addReg(BaseReg1)
                     .addImm(LowDisp);
      // Add implicit-use for the odd register.
      MIB.addReg(OddReg, RegState::Implicit);

      // Save the new instruction iterator before erasing.
      auto NewIt = MIB->getIterator();

      LowMI->eraseFromParent();
      HighMI->eraseFromParent();

      // Advance past the newly created ST.DW instruction.
      MBBI = std::next(NewIt);

      ++NumStoresMerged;
      Changed = true;
      Merged = true;
      break;
    }

    if (!Merged)
      ++MBBI;
  }

  return Changed;
}

bool V850LoadStoreOptimizer::runOnMachineFunction(MachineFunction &MF) {
  STI = &MF.getSubtarget<V850Subtarget>();
  TII = STI->getInstrInfo();
  TRI = STI->getRegisterInfo();

  bool Changed = false;

  // Short format promotion requires V850E1 or later.
  if (STI->hasV850E1()) {
    for (MachineBasicBlock &MBB : MF) {
      for (MachineInstr &MI : llvm::make_early_inc_range(MBB)) {
        switch (MI.getOpcode()) {
        case V850::LDW:
          if (tryPromoteToShortLoad(MI)) {
            Changed = true;
            ++NumLoadsPromoted;
          }
          break;
        case V850::STW:
          if (tryPromoteToShortStore(MI)) {
            Changed = true;
            ++NumStoresPromoted;
          }
          break;
        default:
          break;
        }
      }
    }
  }

  // LD.DW/ST.DW merging requires RH850G3M or later.
  if (STI->hasRH850G3M()) {
    for (MachineBasicBlock &MBB : MF) {
      Changed |= tryMergeLoadPair(MBB);
      Changed |= tryMergeStorePair(MBB);
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

  BuildMI(*MBB, MI, DL, TII->get(V850::SLDW), DestReg).addImm(ShortDisp);

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

  BuildMI(*MBB, MI, DL, TII->get(V850::SSTW)).addReg(SrcReg).addImm(ShortDisp);

  // Remove the original instruction
  MI.eraseFromParent();

  return true;
}

FunctionPass *llvm::createV850LoadStoreOptimizerPass() {
  return new V850LoadStoreOptimizer();
}
