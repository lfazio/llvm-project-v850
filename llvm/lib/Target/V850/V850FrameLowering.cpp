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
  const TargetRegisterInfo *RegInfo = MF.getSubtarget().getRegisterInfo();

  // ABI-required frame pointer or user requested via -fno-omit-frame-pointer
  if (MF.getTarget().Options.DisableFramePointerElim(MF))
    return true;

  // Frame pointer required for variable-sized stack allocations (alloca)
  if (MFI.hasVarSizedObjects())
    return true;

  // Frame pointer required when address of frame is taken
  if (MFI.isFrameAddressTaken())
    return true;

  // Frame pointer required for stack realignment
  if (RegInfo->hasStackRealignment(MF))
    return true;

  return false;
}

bool V850FrameLowering::hasReservedCallFrame(const MachineFunction &MF) const {
  return !MF.getFrameInfo().hasVarSizedObjects();
}

bool V850FrameLowering::enableShrinkWrapping(const MachineFunction &MF) const {
  // Keep the conventional code flow when not optimizing.
  if (MF.getFunction().hasOptNone())
    return false;

  return true;
}

void V850FrameLowering::emitPrologue(MachineFunction &MF,
                                     MachineBasicBlock &MBB) const {
  // Note: With shrink-wrapping enabled, MBB may not be the entry block.
  // The prologue is inserted at the shrink-wrapped location.
  MachineFrameInfo &MFI = MF.getFrameInfo();
  const V850InstrInfo &TII =
      *static_cast<const V850InstrInfo *>(MF.getSubtarget().getInstrInfo());

  MachineBasicBlock::iterator MBBI = MBB.begin();

  // Skip past any PREPARE instruction (CSR saves) so that prologue code
  // (especially FP setup) comes after CSR saves. This is required because
  // PREPARE saves the old register values before modification.
  while (MBBI != MBB.end() && MBBI->getOpcode() == V850::PREPARE)
    ++MBBI;

  DebugLoc DL = MBBI != MBB.end() ? MBBI->getDebugLoc() : DebugLoc();

  // Get the number of bytes to allocate from the FrameInfo
  uint64_t StackSize = MFI.getStackSize();

  if (StackSize == 0)
    return;

  // Adjust stack pointer: SP = SP - StackSize
  // Prefer 16-bit ADDi for small offsets, then 32-bit ADDI, then use a register
  int64_t NegStackSize = -static_cast<int64_t>(StackSize);
  if (isInt<5>(NegStackSize)) {
    // 16-bit ADDi for small offsets (-16 to +15)
    BuildMI(MBB, MBBI, DL, TII.get(V850::ADDi), V850::SP)
        .addImm(NegStackSize)
        .addReg(V850::SP)
        .setMIFlag(MachineInstr::FrameSetup);
  } else if (isInt<16>(NegStackSize)) {
    // 32-bit ADDI for medium offsets
    BuildMI(MBB, MBBI, DL, TII.get(V850::ADDI), V850::SP)
        .addReg(V850::SP)
        .addImm(NegStackSize)
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
    // Prefer 16-bit ADDi for small offsets
    if (isInt<5>(StackSize)) {
      // 16-bit ADDi for small offsets (-16 to +15)
      BuildMI(MBB, MBBI, DL, TII.get(V850::ADDi), V850::SP)
          .addImm(StackSize)
          .addReg(V850::SP)
          .setMIFlag(MachineInstr::FrameDestroy);
    } else if (isInt<16>(StackSize)) {
      // 32-bit ADDI for medium offsets
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

  // Try to use PREPARE instruction (V850E1+)
  if (canUsePrepareDispose(MF, CSI)) {
    unsigned List12 = buildList12Mask(CSI);

    // Add all callee-saved registers as live-in
    for (const CalleeSavedInfo &I : CSI)
      MBB.addLiveIn(I.getReg());

    // PREPARE list12, imm5
    // imm5 = 0 (no additional stack allocation via PREPARE; emitPrologue handles it)
    BuildMI(MBB, MI, DL, TII.get(V850::PREPARE))
        .addImm(List12)
        .addImm(0)
        .setMIFlag(MachineInstr::FrameSetup);

    return true;
  }

  // Fallback: use individual store instructions
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

  // Try to use DISPOSE instruction (V850E1+)
  if (canUsePrepareDispose(MF, CSI)) {
    unsigned List12 = buildList12Mask(CSI);

    // Check if we can use DISPOSEr to combine restore and return
    // This is only valid if MI points to a RET instruction
    bool UseDisposeWithReturn = false;
    if (MI != MBB.end() && MI->getOpcode() == V850::RET) {
      UseDisposeWithReturn = true;
    }

    if (UseDisposeWithReturn) {
      // DISPOSEr imm5, list12, [LP] - restore, deallocate, and return
      // imm5 = 0 (emitEpilogue handles remaining stack adjustment)
      BuildMI(MBB, MI, DL, TII.get(V850::DISPOSEr))
          .addImm(0)
          .addImm(List12)
          .addReg(V850::LP)
          .setMIFlag(MachineInstr::FrameDestroy);

      // Remove the original RET instruction since DISPOSEr includes the return
      MI->eraseFromParent();
    } else {
      // DISPOSE imm5, list12 - restore without return
      BuildMI(MBB, MI, DL, TII.get(V850::DISPOSE))
          .addImm(0)
          .addImm(List12)
          .setMIFlag(MachineInstr::FrameDestroy);
    }

    return true;
  }

  // Fallback: use individual load instructions
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
        // Subtract from SP - prefer 16-bit ADDi for small offsets
        if (isInt<5>(-Amount)) {
          BuildMI(MBB, I, MI.getDebugLoc(), TII.get(V850::ADDi), V850::SP)
              .addImm(-Amount)
              .addReg(V850::SP);
        } else {
          BuildMI(MBB, I, MI.getDebugLoc(), TII.get(V850::ADDI), V850::SP)
              .addReg(V850::SP)
              .addImm(-Amount);
        }
      } else {
        assert(MI.getOpcode() == V850::ADJCALLSTACKUP);
        // Add to SP - prefer 16-bit ADDi for small offsets
        if (isInt<5>(Amount)) {
          BuildMI(MBB, I, MI.getDebugLoc(), TII.get(V850::ADDi), V850::SP)
              .addImm(Amount)
              .addReg(V850::SP);
        } else {
          BuildMI(MBB, I, MI.getDebugLoc(), TII.get(V850::ADDI), V850::SP)
              .addReg(V850::SP)
              .addImm(Amount);
        }
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

//===----------------------------------------------------------------------===//
// PREPARE/DISPOSE Support (V850E1+)
//===----------------------------------------------------------------------===//

bool V850FrameLowering::canUsePrepareDispose(
    const MachineFunction &MF, ArrayRef<CalleeSavedInfo> CSI) const {
  // PREPARE/DISPOSE requires V850E1 or later
  const V850Subtarget &Subtarget = MF.getSubtarget<V850Subtarget>();
  if (!Subtarget.hasV850E1())
    return false;

  // When frame pointer is used, the epilogue restores SP from FP which
  // conflicts with DISPOSE's stack pointer handling. Disable for now.
  // TODO: Handle FP case by excluding r29 from list12 or adjusting SP.
  if (hasFP(MF))
    return false;

  // Check that all callee-saved registers are in r20-r31 range
  for (const CalleeSavedInfo &I : CSI) {
    Register Reg = I.getReg();
    unsigned HWReg = TRI->getEncodingValue(Reg);
    // list12 covers registers r20-r31 (hardware encodings 20-31)
    if (HWReg < 20 || HWReg > 31)
      return false;
  }

  return true;
}

unsigned V850FrameLowering::buildList12Mask(ArrayRef<CalleeSavedInfo> CSI) const {
  unsigned List12 = 0;

  for (const CalleeSavedInfo &I : CSI) {
    Register Reg = I.getReg();
    unsigned HWReg = TRI->getEncodingValue(Reg);
    // list12 bit N corresponds to register r(20+N)
    // bit 0 = r20, bit 1 = r21, ..., bit 9 = r29, bit 10 = r30(EP), bit 11 = r31(LP)
    if (HWReg >= 20 && HWReg <= 31) {
      List12 |= (1 << (HWReg - 20));
    }
  }

  return List12;
}
