//===-- V850RegisterInfo.cpp - V850 Register Information ------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the V850 implementation of the TargetRegisterInfo class.
//
//===----------------------------------------------------------------------===//

#include "V850RegisterInfo.h"
#include "V850.h"
#include "V850FrameLowering.h"
#include "V850MachineFunctionInfo.h"
#include "V850Subtarget.h"
#include "llvm/ADT/BitVector.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/TargetInstrInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetOptions.h"

using namespace llvm;

#define DEBUG_TYPE "v850-reg-info"

#define GET_REGINFO_TARGET_DESC
#include "V850GenRegisterInfo.inc"

V850RegisterInfo::V850RegisterInfo() : V850GenRegisterInfo(V850::LP) {}

const MCPhysReg *
V850RegisterInfo::getCalleeSavedRegs(const MachineFunction *MF) const {
  // Interrupt handlers must preserve all registers
  if (MF) {
    const V850MachineFunctionInfo *FuncInfo =
        MF->getInfo<V850MachineFunctionInfo>();
    if (FuncInfo->isInterruptHandler())
      return CSR_V850_Interrupt_SaveList;
  }

  // V850 calling convention: r20-r29, r30 (EP), r31 (LP) are callee-saved
  return CSR_V850_SaveList;
}

BitVector V850RegisterInfo::getReservedRegs(const MachineFunction &MF) const {
  BitVector Reserved(getNumRegs());
  const V850FrameLowering *TFI = getFrameLowering(MF);

  // r0 is always zero
  Reserved.set(V850::R0);

  // r1 is assembler temporary
  Reserved.set(V850::R1);

  // r2 is reserved for RTOS
  Reserved.set(V850::R2);

  // r3 (SP) is stack pointer
  Reserved.set(V850::SP);

  // r4 (GP) is global pointer - reserve for now
  Reserved.set(V850::GP);

  // r5 (TP) is text pointer - reserve for now
  Reserved.set(V850::TP);

  // Reserve DPR pairs whose sub-registers are all reserved.
  // D2=[R2,SP] and D4=[GP,TP]: if their sub-registers are reserved, the pair
  // must also be reserved so that isReservedRegUnit() returns true for SP/GP/TP
  // register units (otherwise LiveIntervals crashes on non-entry-block calls).
  // D0=[R0,R1]: likewise for the zero/assembler-temp pair.
  // D30=[EP,LP] is intentionally NOT reserved since EP and LP are not reserved.
  Reserved.set(V850::D0);
  Reserved.set(V850::D2);
  Reserved.set(V850::D4);

  // Mark frame pointer as reserved if needed
  if (TFI->hasFP(MF)) {
    // Use r29 as frame pointer when needed
    Reserved.set(V850::R29);
  }

  return Reserved;
}

const TargetRegisterClass *
V850RegisterInfo::getPointerRegClass(const MachineFunction &MF,
                                     unsigned Kind) const {
  return &V850::GPRRegClass;
}

bool V850RegisterInfo::eliminateFrameIndex(MachineBasicBlock::iterator II,
                                           int SPAdj, unsigned FIOperandNum,
                                           RegScavenger *RS) const {
  MachineInstr &MI = *II;
  MachineBasicBlock &MBB = *MI.getParent();
  MachineFunction &MF = *MBB.getParent();
  const V850FrameLowering *TFI = getFrameLowering(MF);
  DebugLoc DL = MI.getDebugLoc();
  int FrameIndex = MI.getOperand(FIOperandNum).getIndex();

  Register BasePtr = TFI->hasFP(MF) ? V850::R29 : V850::SP;
  int Offset = MF.getFrameInfo().getObjectOffset(FrameIndex);

  // Object offsets are relative to CFA (caller's SP).
  // Convert to base register-relative offset.
  if (!TFI->hasFP(MF)) {
    // SP = CFA - StackSize, so offset from SP is:
    // object at CFA + objOffset = SP + StackSize + objOffset
    Offset += MF.getFrameInfo().getStackSize();
  } else {
    // FP points to where old FP was saved (for frame pointer chain).
    // FP = CFA - FPOffset (where FPOffset is offset from CFA to saved r29)
    // Object at CFA + objOffset = FP + FPOffset + objOffset
    V850MachineFunctionInfo *FuncInfo = MF.getInfo<V850MachineFunctionInfo>();
    int FPOffset = FuncInfo->getFPOffset();
    Offset += FPOffset;
  }

  // Fold immediate offset if present
  if (MI.getNumOperands() > FIOperandNum + 1 &&
      MI.getOperand(FIOperandNum + 1).isImm()) {
    Offset += MI.getOperand(FIOperandNum + 1).getImm();
    MI.getOperand(FIOperandNum + 1).ChangeToImmediate(Offset);
  }

  MI.getOperand(FIOperandNum).ChangeToRegister(BasePtr, false);
  return false;
}

const uint32_t *
V850RegisterInfo::getCallPreservedMask(const MachineFunction &MF,
                                       CallingConv::ID CC) const {
  // Interrupt handlers preserve all registers
  const V850MachineFunctionInfo *FuncInfo =
      MF.getInfo<V850MachineFunctionInfo>();
  if (FuncInfo->isInterruptHandler())
    return CSR_V850_Interrupt_RegMask;

  return CSR_V850_RegMask;
}

Register V850RegisterInfo::getFrameRegister(const MachineFunction &MF) const {
  const V850FrameLowering *TFI = getFrameLowering(MF);
  return TFI->hasFP(MF) ? V850::R29 : V850::SP;
}
