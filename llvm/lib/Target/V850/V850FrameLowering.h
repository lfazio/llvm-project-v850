//===-- V850FrameLowering.h - Define frame lowering for V850 ---*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This class implements V850-specific bits of TargetFrameLowering class.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V850_V850FRAMELOWERING_H
#define LLVM_LIB_TARGET_V850_V850FRAMELOWERING_H

#include "V850.h"
#include "llvm/CodeGen/TargetFrameLowering.h"

namespace llvm {

class V850Subtarget;
class V850InstrInfo;
class V850RegisterInfo;

class V850FrameLowering : public TargetFrameLowering {
protected:
  bool hasFPImpl(const MachineFunction &MF) const override;

public:
  explicit V850FrameLowering(const V850Subtarget &STI);

  const V850Subtarget &STI;
  const V850InstrInfo &TII;
  const V850RegisterInfo *TRI;

  /// emitProlog/emitEpilog - These methods insert prolog and epilog code into
  /// the function.
  void emitPrologue(MachineFunction &MF, MachineBasicBlock &MBB) const override;
  void emitEpilogue(MachineFunction &MF, MachineBasicBlock &MBB) const override;

  MachineBasicBlock::iterator
  eliminateCallFramePseudoInstr(MachineFunction &MF, MachineBasicBlock &MBB,
                                MachineBasicBlock::iterator I) const override;

  bool spillCalleeSavedRegisters(MachineBasicBlock &MBB,
                                 MachineBasicBlock::iterator MI,
                                 ArrayRef<CalleeSavedInfo> CSI,
                                 const TargetRegisterInfo *TRI) const override;

  bool
  restoreCalleeSavedRegisters(MachineBasicBlock &MBB,
                              MachineBasicBlock::iterator MI,
                              MutableArrayRef<CalleeSavedInfo> CSI,
                              const TargetRegisterInfo *TRI) const override;

  bool hasReservedCallFrame(const MachineFunction &MF) const override;

  /// Enable shrink wrapping for V850 when optimizing.
  /// Shrink wrapping moves prologue/epilogue code closer to where registers
  /// are actually used, reducing overhead on early-exit paths.
  bool enableShrinkWrapping(const MachineFunction &MF) const override;

  void determineCalleeSaves(MachineFunction &MF, BitVector &SavedRegs,
                            RegScavenger *RS = nullptr) const override;

private:
  /// Check if PREPARE/DISPOSE instructions can be used for the given CSI.
  /// Returns true if V850E1+ and all registers are in r20-r31 range.
  bool canUsePrepareDispose(const MachineFunction &MF,
                            ArrayRef<CalleeSavedInfo> CSI) const;

  /// Build the list12 register mask for PREPARE/DISPOSE from CSI.
  /// Returns the 12-bit mask where bit N corresponds to register r(20+N).
  unsigned buildList12Mask(ArrayRef<CalleeSavedInfo> CSI) const;
};

} // end namespace llvm

#endif // LLVM_LIB_TARGET_V850_V850FRAMELOWERING_H
