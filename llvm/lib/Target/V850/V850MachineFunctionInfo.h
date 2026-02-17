//===-- V850MachineFunctionInfo.h - V850 machine function info --*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file declares V850-specific per-machine-function information.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V850_V850MACHINEFUNCTIONINFO_H
#define LLVM_LIB_TARGET_V850_V850MACHINEFUNCTIONINFO_H

#include "llvm/CodeGen/MachineFunction.h"

namespace llvm {

/// V850MachineFunctionInfo - This class is derived from MachineFunctionInfo
/// and contains private V850-specific information for each MachineFunction.
class V850MachineFunctionInfo : public MachineFunctionInfo {
  /// VarArgsFrameIndex - FrameIndex for start of varargs area.
  int VarArgsFrameIndex = 0;

  /// VarArgsSaveSize - Size of the save area used for varargs.
  unsigned VarArgsSaveSize = 0;

  /// CalleeSavedStackSize - Size of the callee-saved register portion of the
  /// stack frame in bytes.
  unsigned CalleeSavedStackSize = 0;

  /// FPOffset - Offset from SP to where the frame pointer (r29) was saved.
  /// Used to set up proper frame pointer chain where [FP] = old FP.
  /// Only valid when frame pointer is used.
  int FPOffset = 0;

  /// IsInterruptHandler - Whether or not the function is an interrupt handler.
  bool IsInterruptHandler = false;

  /// UsesPrepareDispose - Whether PREPARE/DISPOSE instructions are used for
  /// callee-saved register save/restore. When true, CSRs are handled separately
  /// from the local frame. When false, CSRs are part of the main stack frame.
  bool UsesPrepareDispose = false;

  /// UsesPushspPopsp - Whether PUSHSP/POPSP instructions are used for
  /// callee-saved register save/restore. Similar to PREPARE/DISPOSE but
  /// supports any contiguous register range (not limited to r20-r31).
  /// Available on RH850G3M+ only.
  bool UsesPushspPopsp = false;

public:
  V850MachineFunctionInfo(const Function &F, const TargetSubtargetInfo *STI) {
    // Check for interrupt handler attribute
    IsInterruptHandler = F.hasFnAttribute("interrupt");
  }

  MachineFunctionInfo *
  clone(BumpPtrAllocator &Allocator, MachineFunction &DestMF,
        const DenseMap<MachineBasicBlock *, MachineBasicBlock *> &Src2DstMBB)
      const override {
    return DestMF.cloneInfo<V850MachineFunctionInfo>(*this);
  }

  int getVarArgsFrameIndex() const { return VarArgsFrameIndex; }
  void setVarArgsFrameIndex(int Index) { VarArgsFrameIndex = Index; }

  unsigned getVarArgsSaveSize() const { return VarArgsSaveSize; }
  void setVarArgsSaveSize(unsigned Size) { VarArgsSaveSize = Size; }

  unsigned getCalleeSavedStackSize() const { return CalleeSavedStackSize; }
  void setCalleeSavedStackSize(unsigned Size) { CalleeSavedStackSize = Size; }

  int getFPOffset() const { return FPOffset; }
  void setFPOffset(int Offset) { FPOffset = Offset; }

  bool isInterruptHandler() const { return IsInterruptHandler; }
  void setIsInterruptHandler(bool B) { IsInterruptHandler = B; }

  bool usesPrepareDispose() const { return UsesPrepareDispose; }
  void setUsesPrepareDispose(bool B) { UsesPrepareDispose = B; }

  bool usesPushspPopsp() const { return UsesPushspPopsp; }
  void setUsesPushspPopsp(bool B) { UsesPushspPopsp = B; }

  /// Returns true if CSR save/restore uses a bulk instruction (PREPARE or
  /// PUSHSP) that allocates CSR space separately from the local frame.
  bool usesBlockCSRSave() const {
    return UsesPrepareDispose || UsesPushspPopsp;
  }
};

} // end namespace llvm

#endif // LLVM_LIB_TARGET_V850_V850MACHINEFUNCTIONINFO_H
