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
#include "V850MachineFunctionInfo.h"
#include "V850Subtarget.h"
#include "llvm/CodeGen/CFIInstBuilder.h"
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
  V850MachineFunctionInfo *FuncInfo = MF.getInfo<V850MachineFunctionInfo>();

  MachineBasicBlock::iterator MBBI = MBB.begin();

  // Skip past any PREPARE instruction and its associated CFI directives
  // so that prologue code (especially FP setup) comes after CSR saves.
  // This is required because PREPARE saves the old register values before
  // modification, and CFI directives must follow their associated instructions.
  bool UsedPrepare = false;
  while (MBBI != MBB.end() &&
         (MBBI->getOpcode() == V850::PREPARE ||
          MBBI->getOpcode() == TargetOpcode::CFI_INSTRUCTION)) {
    if (MBBI->getOpcode() == V850::PREPARE)
      UsedPrepare = true;
    ++MBBI;
  }

  DebugLoc DL = MBBI != MBB.end() ? MBBI->getDebugLoc() : DebugLoc();

  // Get the number of bytes to allocate from the FrameInfo
  uint64_t StackSize = MFI.getStackSize();

  if (StackSize == 0)
    return;

  // Calculate total CFA offset for CFI directives.
  // - With PREPARE: CSRs are saved by PREPARE (separate from StackSize),
  //   so total CFA offset = CalleeSavedSize + StackSize.
  // - Without PREPARE: CSR space is included in StackSize (via frame indices),
  //   so total CFA offset = StackSize.
  unsigned CalleeSavedSize = FuncInfo->getCalleeSavedStackSize();
  int64_t TotalCFAOffset =
      UsedPrepare ? CalleeSavedSize + StackSize : StackSize;

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

  // Emit CFI directive for total CFA offset (callee-saved + locals)
  CFIInstBuilder CFIBuilder(MBB, MBBI, MachineInstr::FrameSetup);
  CFIBuilder.buildDefCFAOffset(TotalCFAOffset);

  // Set up frame pointer if needed
  // For proper frame pointer chain, FP should point to where old FP was saved
  // so that [FP] = previous frame's FP. This enables debuggers to walk the
  // stack.
  //
  // Frame layout (growing downward):
  //   [CFA = original SP]
  //   [CalleeSavedSize bytes of saved registers at CFA-4, CFA-8, ...]
  //   [LocalFrameSize bytes of local variables]
  //   [SP after complete prologue = CFA - StackSize]
  //
  // FPOffset = offset from CFA to saved r29 (e.g., 12 means r29 at CFA-12)
  // FP should point to saved r29: FP = CFA - FPOffset
  // Since SP = CFA - StackSize: FP = SP + (StackSize - FPOffset)
  if (hasFP(MF)) {
    int FPOffset = FuncInfo->getFPOffset();
    int FPFromSP = StackSize - FPOffset;

    // FP = SP + FPFromSP (to point to saved r29 location)
    if (FPFromSP == 0) {
      // FP = SP
      BuildMI(MBB, MBBI, DL, TII.get(V850::MOV), V850::R29)
          .addReg(V850::SP)
          .setMIFlag(MachineInstr::FrameSetup);
    } else if (isInt<16>(FPFromSP)) {
      // FP = SP + FPFromSP using ADDI
      BuildMI(MBB, MBBI, DL, TII.get(V850::ADDI), V850::R29)
          .addReg(V850::SP)
          .addImm(FPFromSP)
          .setMIFlag(MachineInstr::FrameSetup);
    } else {
      // For large offsets, use MOVHI + ADDI + ADD
      BuildMI(MBB, MBBI, DL, TII.get(V850::MOVHI), V850::R29)
          .addImm((FPFromSP >> 16) & 0xFFFF)
          .addReg(V850::R0)
          .setMIFlag(MachineInstr::FrameSetup);
      BuildMI(MBB, MBBI, DL, TII.get(V850::ADDI), V850::R29)
          .addReg(V850::R29)
          .addImm(FPFromSP & 0xFFFF)
          .setMIFlag(MachineInstr::FrameSetup);
      BuildMI(MBB, MBBI, DL, TII.get(V850::ADD), V850::R29)
          .addReg(V850::SP)
          .addReg(V850::R29)
          .setMIFlag(MachineInstr::FrameSetup);
    }

    // CFI: CFA = FP + FPOffset
    // FP points to saved r29 at CFA - FPOffset, so CFA = FP + FPOffset
    CFIBuilder.setInsertPoint(MBBI);
    CFIBuilder.buildDefCFA(V850::R29, FPOffset);
  }
}

void V850FrameLowering::emitEpilogue(MachineFunction &MF,
                                     MachineBasicBlock &MBB) const {
  MachineFrameInfo &MFI = MF.getFrameInfo();
  const V850InstrInfo &TII =
      *static_cast<const V850InstrInfo *>(MF.getSubtarget().getInstrInfo());
  V850MachineFunctionInfo *FuncInfo = MF.getInfo<V850MachineFunctionInfo>();

  MachineBasicBlock::iterator MBBI = MBB.getLastNonDebugInstr();
  DebugLoc DL = MBBI->getDebugLoc();

  // Get the number of bytes to deallocate
  uint64_t StackSize = MFI.getStackSize();

  if (StackSize == 0)
    return;

  // Restore stack pointer from frame pointer if used
  // FP = SP + (StackSize - FPOffset)
  // So SP = FP - (StackSize - FPOffset) = FP - StackSize + FPOffset
  if (hasFP(MF)) {
    int FPOffset = FuncInfo->getFPOffset();
    int SPFromFP = FPOffset - static_cast<int>(StackSize);

    if (SPFromFP == 0) {
      // SP = FP
      BuildMI(MBB, MBBI, DL, TII.get(V850::MOV), V850::SP)
          .addReg(V850::R29)
          .setMIFlag(MachineInstr::FrameDestroy);
    } else if (isInt<16>(SPFromFP)) {
      // SP = FP + SPFromFP using ADDI
      BuildMI(MBB, MBBI, DL, TII.get(V850::ADDI), V850::SP)
          .addReg(V850::R29)
          .addImm(SPFromFP)
          .setMIFlag(MachineInstr::FrameDestroy);
    } else {
      // For large offsets, use MOVHI + ADDI + ADD
      BuildMI(MBB, MBBI, DL, TII.get(V850::MOVHI), V850::R1)
          .addImm((SPFromFP >> 16) & 0xFFFF)
          .addReg(V850::R0)
          .setMIFlag(MachineInstr::FrameDestroy);
      BuildMI(MBB, MBBI, DL, TII.get(V850::ADDI), V850::R1)
          .addReg(V850::R1)
          .addImm(SPFromFP & 0xFFFF)
          .setMIFlag(MachineInstr::FrameDestroy);
      BuildMI(MBB, MBBI, DL, TII.get(V850::ADD), V850::SP)
          .addReg(V850::R29)
          .addReg(V850::R1)
          .setMIFlag(MachineInstr::FrameDestroy);
    }

    // After restoring SP from FP, switch CFA back to SP-based
    // For PREPARE/DISPOSE: CSRs are still on stack, CFA = SP + CalleeSavedSize
    // For fallback: everything is deallocated, CFA = SP + 0
    unsigned CalleeSavedSize = FuncInfo->getCalleeSavedStackSize();
    CFIInstBuilder CFIBuilder(MBB, MBBI, MachineInstr::FrameDestroy);
    if (FuncInfo->usesPrepareDispose()) {
      CFIBuilder.buildDefCFA(V850::SP, CalleeSavedSize);
    } else {
      CFIBuilder.buildDefCFA(V850::SP, 0);
    }
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

    // After stack deallocation, update CFA offset
    // For PREPARE/DISPOSE: CSRs are still on stack, CFA = SP + CalleeSavedSize
    // For fallback: everything is deallocated, CFA = SP + 0
    unsigned CalleeSavedSize = FuncInfo->getCalleeSavedStackSize();
    CFIInstBuilder CFIBuilder(MBB, MBBI, MachineInstr::FrameDestroy);
    if (FuncInfo->usesPrepareDispose()) {
      // PREPARE/DISPOSE: local frame deallocated, CSRs remain
      CFIBuilder.buildDefCFAOffset(CalleeSavedSize);
    } else if (CalleeSavedSize > 0) {
      // Fallback: entire frame (including CSRs) deallocated
      CFIBuilder.buildDefCFAOffset(0);
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
  V850MachineFunctionInfo *FuncInfo = MF.getInfo<V850MachineFunctionInfo>();

  // Calculate total size of callee-saved registers
  unsigned CalleeSavedSize = CSI.size() * 4; // Each register is 4 bytes
  FuncInfo->setCalleeSavedStackSize(CalleeSavedSize);

  // Calculate FP offset: where is r29 saved relative to CFA?
  // This is needed for proper frame pointer chain where [FP] = old FP.
  //
  // Frame layout (CSRs stored at negative offsets from CFA):
  //   CFA - 4:  first CSR (CSI[0])
  //   CFA - 8:  second CSR (CSI[1])
  //   ...
  //   CFA - (i+1)*4: CSR at index i (CSI[i])
  //
  // For r29 at CSI index i: r29 is at CFA - (i+1)*4
  // FPOffset = (i+1)*4 represents the offset from CFA to where r29 is saved.
  if (hasFP(MF)) {
    int FPOffset = CalleeSavedSize; // Default: last position if not found
    for (unsigned i = 0; i < CSI.size(); ++i) {
      if (CSI[i].getReg() == V850::R29) {
        // r29 at CFA - (i+1)*4, so FPOffset = (i+1)*4
        FPOffset = (i + 1) * 4;
        break;
      }
    }
    FuncInfo->setFPOffset(FPOffset);
  }

  // Try to use PREPARE instruction (V850E1+)
  if (canUsePrepareDispose(MF, CSI)) {
    unsigned List12 = buildList12Mask(CSI);

    // Mark that we're using PREPARE/DISPOSE (CSR area is separate from local
    // frame)
    FuncInfo->setUsesPrepareDispose(true);

    // Add all callee-saved registers as live-in
    for (const CalleeSavedInfo &I : CSI)
      MBB.addLiveIn(I.getReg());

    // PREPARE list12, imm5
    // imm5 = 0 (no additional stack allocation via PREPARE; emitPrologue
    // handles it)
    MachineInstrBuilder MIB = BuildMI(MBB, MI, DL, TII.get(V850::PREPARE))
                                  .addImm(List12)
                                  .addImm(0)
                                  .setMIFlag(MachineInstr::FrameSetup);

    // Emit CFI directives immediately after PREPARE
    // PREPARE saves registers from LP (bit 11) to r20 (bit 0) in order
    // LP is at SP-4, next register at SP-8, etc.
    MachineBasicBlock::iterator CFIInsertPt =
        std::next(MIB.getInstr()->getIterator());
    CFIInstBuilder CFIBuilder(MBB, CFIInsertPt, MachineInstr::FrameSetup);

    // First emit def_cfa_offset for the total callee-saved area
    CFIBuilder.buildDefCFAOffset(CalleeSavedSize);

    // Emit cfi_offset for each saved register
    // PREPARE pushes in this order: LP, EP, r29, r28, ..., r20
    // We need to emit CFI in the actual push order
    int Offset = -4; // First register at CFA-4
    static const unsigned PrepareOrder[] = {
        V850::LP,  V850::EP,  V850::R29, V850::R28, V850::R27, V850::R26,
        V850::R25, V850::R24, V850::R23, V850::R22, V850::R21, V850::R20};
    for (unsigned Reg : PrepareOrder) {
      if (List12 & (1 << (this->TRI->getEncodingValue(Reg) - 20))) {
        CFIBuilder.buildOffset(Reg, Offset);
        Offset -= 4;
      }
    }

    return true;
  }

  // Fallback: use individual store instructions
  CFIInstBuilder CFIBuilder(MBB, MI, MachineInstr::FrameSetup);
  int Offset = -4;

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

    // Emit CFI offset for this register
    CFIBuilder.buildOffset(Reg, Offset);
    Offset -= 4;
  }

  // Note: In the non-PREPARE fallback case, the stack frame (including CSR
  // space) is allocated by emitPrologue via MachineFrameInfo::getStackSize().
  // emitPrologue handles the cfi_def_cfa_offset directive, so we don't emit
  // it here. This is different from the PREPARE case where PREPARE allocates
  // the CSR area and we emit cfi_def_cfa_offset immediately after.

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
      MachineInstrBuilder MIB = BuildMI(MBB, MI, DL, TII.get(V850::DISPOSEr))
                                    .addImm(0)
                                    .addImm(List12)
                                    .addReg(V850::LP)
                                    .setMIFlag(MachineInstr::FrameDestroy);

      // Copy implicit operands from RET (e.g., "implicit $r10" for return
      // value) This is essential to prevent Machine Copy Propagation from
      // removing the return value copy as dead code.
      for (const MachineOperand &MO : MI->operands()) {
        if (MO.isReg() && MO.isImplicit())
          MIB.add(MO);
      }

      // Remove the original RET instruction since DISPOSEr includes the return
      MI->eraseFromParent();
    } else {
      // DISPOSE imm5, list12 - restore without return
      BuildMI(MBB, MI, DL, TII.get(V850::DISPOSE))
          .addImm(0)
          .addImm(List12)
          .setMIFlag(MachineInstr::FrameDestroy);
    }

    // Note: CFI restore directives are not emitted in the epilogue because
    // unwinding uses the CFI state from the prologue. This follows the
    // "prologue-only" CFI philosophy used by most LLVM backends.
    // The key CFI information for unwinding is emitted in
    // spillCalleeSavedRegisters.

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

  // Note: CFI restore directives are not emitted in the epilogue because
  // unwinding uses the CFI state from the prologue.

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

  // For interrupt handlers, save ALL caller-saved registers because we
  // don't know what state the interrupted code was in. The CSR_V850_Interrupt
  // list marks all registers as callee-saved for the allocator, but we also
  // need to physically save them in the prologue.
  const V850MachineFunctionInfo *FuncInfo =
      MF.getInfo<V850MachineFunctionInfo>();
  if (FuncInfo->isInterruptHandler()) {
    // Caller-saved registers: r1, r6-r19
    // (r0 is zero and doesn't need saving, r2-r5 are special)
    SavedRegs.set(V850::R1);
    for (unsigned Reg = V850::R6; Reg <= V850::R19; ++Reg)
      SavedRegs.set(Reg);
    // Also save LP (r31) for the return address
    SavedRegs.set(V850::LP);
  }

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

unsigned
V850FrameLowering::buildList12Mask(ArrayRef<CalleeSavedInfo> CSI) const {
  unsigned List12 = 0;

  for (const CalleeSavedInfo &I : CSI) {
    Register Reg = I.getReg();
    unsigned HWReg = TRI->getEncodingValue(Reg);
    // list12 bit N corresponds to register r(20+N)
    // bit 0 = r20, bit 1 = r21, ..., bit 9 = r29, bit 10 = r30(EP), bit 11 =
    // r31(LP)
    if (HWReg >= 20 && HWReg <= 31) {
      List12 |= (1 << (HWReg - 20));
    }
  }

  return List12;
}
