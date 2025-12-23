//===-- V850FrameLowering.cpp - V850 Frame Information --------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the V850 implementation of TargetFrameLowering class.
//
//===----------------------------------------------------------------------===//

#include "V850FrameLowering.h"
#include "V850InstrInfo.h"
#include "V850Subtarget.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/Target/TargetOptions.h"

using namespace llvm;

V850FrameLowering::V850FrameLowering(const V850Subtarget &STI)
    : TargetFrameLowering(TargetFrameLowering::StackGrowsDown,
                          /*StackAlignment=*/Align(4),
                          /*LocalAreaOffset=*/0,
                          /*TransientStackAlignment=*/Align(4)),
      STI(STI), TII(*STI.getInstrInfo()), TRI(STI.getRegisterInfo()) {}

bool V850FrameLowering::hasFPImpl(const MachineFunction &MF) const {
  const MachineFrameInfo &MFI = MF.getFrameInfo();

  return (MF.getTarget().Options.DisableFramePointerElim(MF) ||
          MFI.hasVarSizedObjects() || MFI.isFrameAddressTaken());
}

bool V850FrameLowering::hasReservedCallFrame(const MachineFunction &MF) const {
  return !MF.getFrameInfo().hasVarSizedObjects();
}

void V850FrameLowering::emitPrologue(MachineFunction &MF,
                                     MachineBasicBlock &MBB) const {
  assert(&MF.front() == &MBB && "Shrink-wrapping not yet supported");
  MachineFrameInfo &MFI = MF.getFrameInfo();
  const V850InstrInfo &TII =
      *static_cast<const V850InstrInfo *>(MF.getSubtarget().getInstrInfo());

  MachineBasicBlock::iterator MBBI = MBB.begin();
  DebugLoc DL = MBBI != MBB.end() ? MBBI->getDebugLoc() : DebugLoc();

  // Get the number of bytes to allocate from the FrameInfo
  uint64_t StackSize = MFI.getStackSize();

  if (StackSize == 0)
    return;

  // Adjust stack pointer: SP = SP - StackSize
  // Use ADDI if the offset fits, otherwise we need to use a register
  if (isInt<16>(-static_cast<int64_t>(StackSize))) {
    BuildMI(MBB, MBBI, DL, TII.get(V850::ADDI), V850::SP)
        .addReg(V850::SP)
        .addImm(-static_cast<int64_t>(StackSize))
        .setMIFlag(MachineInstr::FrameSetup);
  } else {
    // For large frames, load the offset into a temp register first
    // Use r1 (assembler temporary)
    BuildMI(MBB, MBBI, DL, TII.get(V850::MOVHI), V850::R1)
        .addImm(((-static_cast<int64_t>(StackSize)) >> 16) & 0xFFFF)
        .addReg(V850::R0)
        .setMIFlag(MachineInstr::FrameSetup);
    BuildMI(MBB, MBBI, DL, TII.get(V850::ADDI), V850::R1)
        .addReg(V850::R1)
        .addImm((-static_cast<int64_t>(StackSize)) & 0xFFFF)
        .setMIFlag(MachineInstr::FrameSetup);
    BuildMI(MBB, MBBI, DL, TII.get(V850::ADD), V850::SP)
        .addReg(V850::R1)
        .addReg(V850::SP)
        .setMIFlag(MachineInstr::FrameSetup);
  }

  // Set up frame pointer if needed
  if (hasFP(MF)) {
    BuildMI(MBB, MBBI, DL, TII.get(V850::MOV), V850::R29)
        .addReg(V850::SP)
        .setMIFlag(MachineInstr::FrameSetup);
  }
}

void V850FrameLowering::emitEpilogue(MachineFunction &MF,
                                     MachineBasicBlock &MBB) const {
  MachineFrameInfo &MFI = MF.getFrameInfo();
  const V850InstrInfo &TII =
      *static_cast<const V850InstrInfo *>(MF.getSubtarget().getInstrInfo());

  MachineBasicBlock::iterator MBBI = MBB.getLastNonDebugInstr();
  DebugLoc DL = MBBI->getDebugLoc();

  // Get the number of bytes to deallocate
  uint64_t StackSize = MFI.getStackSize();

  if (StackSize == 0)
    return;

  // Restore frame pointer if used
  if (hasFP(MF)) {
    BuildMI(MBB, MBBI, DL, TII.get(V850::MOV), V850::SP)
        .addReg(V850::R29)
        .setMIFlag(MachineInstr::FrameDestroy);
  } else {
    // Adjust stack pointer: SP = SP + StackSize
    if (isInt<16>(StackSize)) {
      BuildMI(MBB, MBBI, DL, TII.get(V850::ADDI), V850::SP)
          .addReg(V850::SP)
          .addImm(StackSize)
          .setMIFlag(MachineInstr::FrameDestroy);
    } else {
      // For large frames, load the offset into a temp register first
      BuildMI(MBB, MBBI, DL, TII.get(V850::MOVHI), V850::R1)
          .addImm((StackSize >> 16) & 0xFFFF)
          .addReg(V850::R0)
          .setMIFlag(MachineInstr::FrameDestroy);
      BuildMI(MBB, MBBI, DL, TII.get(V850::ADDI), V850::R1)
          .addReg(V850::R1)
          .addImm(StackSize & 0xFFFF)
          .setMIFlag(MachineInstr::FrameDestroy);
      BuildMI(MBB, MBBI, DL, TII.get(V850::ADD), V850::SP)
          .addReg(V850::R1)
          .addReg(V850::SP)
          .setMIFlag(MachineInstr::FrameDestroy);
    }
  }
}

bool V850FrameLowering::spillCalleeSavedRegisters(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator MI,
    ArrayRef<CalleeSavedInfo> CSI, const TargetRegisterInfo *TRI) const {
  if (CSI.empty())
    return false;

  DebugLoc DL;
  if (MI != MBB.end())
    DL = MI->getDebugLoc();

  MachineFunction &MF = *MBB.getParent();
  const TargetInstrInfo &TII = *MF.getSubtarget().getInstrInfo();

  for (const CalleeSavedInfo &I : CSI) {
    Register Reg = I.getReg();
    int FI = I.getFrameIdx();

    // Add the callee-saved register as live-in
    MBB.addLiveIn(Reg);

    // Store the register to stack
    BuildMI(MBB, MI, DL, TII.get(V850::STW))
        .addReg(Reg, RegState::Kill)
        .addFrameIndex(FI)
        .addImm(0)
        .setMIFlag(MachineInstr::FrameSetup);
  }

  return true;
}

bool V850FrameLowering::restoreCalleeSavedRegisters(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator MI,
    MutableArrayRef<CalleeSavedInfo> CSI, const TargetRegisterInfo *TRI) const {
  if (CSI.empty())
    return false;

  DebugLoc DL;
  if (MI != MBB.end())
    DL = MI->getDebugLoc();

  MachineFunction &MF = *MBB.getParent();
  const TargetInstrInfo &TII = *MF.getSubtarget().getInstrInfo();

  // Restore in reverse order
  for (const CalleeSavedInfo &I : llvm::reverse(CSI)) {
    Register Reg = I.getReg();
    int FI = I.getFrameIdx();

    BuildMI(MBB, MI, DL, TII.get(V850::LDW), Reg)
        .addFrameIndex(FI)
        .addImm(0)
        .setMIFlag(MachineInstr::FrameDestroy);
  }

  return true;
}

MachineBasicBlock::iterator V850FrameLowering::eliminateCallFramePseudoInstr(
    MachineFunction &MF, MachineBasicBlock &MBB,
    MachineBasicBlock::iterator I) const {
  const V850InstrInfo &TII =
      *static_cast<const V850InstrInfo *>(MF.getSubtarget().getInstrInfo());

  if (!hasReservedCallFrame(MF)) {
    MachineInstr &MI = *I;
    int64_t Amount = MI.getOperand(0).getImm();

    if (Amount != 0) {
      // Round up to maintain stack alignment
      Amount = alignTo(Amount, getStackAlign());

      if (MI.getOpcode() == V850::ADJCALLSTACKDOWN) {
        // Subtract from SP
        BuildMI(MBB, I, MI.getDebugLoc(), TII.get(V850::ADDI), V850::SP)
            .addReg(V850::SP)
            .addImm(-Amount);
      } else {
        assert(MI.getOpcode() == V850::ADJCALLSTACKUP);
        // Add to SP
        BuildMI(MBB, I, MI.getDebugLoc(), TII.get(V850::ADDI), V850::SP)
            .addReg(V850::SP)
            .addImm(Amount);
      }
    }
  }

  return MBB.erase(I);
}

void V850FrameLowering::determineCalleeSaves(MachineFunction &MF,
                                              BitVector &SavedRegs,
                                              RegScavenger *RS) const {
  TargetFrameLowering::determineCalleeSaves(MF, SavedRegs, RS);

  // Always save LP (link pointer) if we have calls
  if (MF.getFrameInfo().hasCalls())
    SavedRegs.set(V850::LP);

  // Save frame pointer if used
  if (hasFP(MF))
    SavedRegs.set(V850::R29);
}
