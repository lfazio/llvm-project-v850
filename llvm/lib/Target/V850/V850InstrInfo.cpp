//===-- V850InstrInfo.cpp - V850 Instruction Information ------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the V850 implementation of the TargetInstrInfo class.
//
//===----------------------------------------------------------------------===//

#include "V850InstrInfo.h"
#include "V850.h"
#include "V850Subtarget.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/MathExtras.h"

using namespace llvm;

#define GET_INSTRINFO_CTOR_DTOR
#include "V850GenInstrInfo.inc"

// Pin the vtable to this file.
void V850InstrInfo::anchor() {}

V850InstrInfo::V850InstrInfo(V850Subtarget &STI)
    : V850GenInstrInfo(V850::ADJCALLSTACKDOWN, V850::ADJCALLSTACKUP), RI() {}

void V850InstrInfo::copyPhysReg(MachineBasicBlock &MBB,
                                MachineBasicBlock::iterator I,
                                const DebugLoc &DL, Register DestReg,
                                Register SrcReg, bool KillSrc,
                                bool RenamableDest, bool RenamableSrc) const {
  if (V850::GPRRegClass.contains(DestReg, SrcReg)) {
    BuildMI(MBB, I, DL, get(V850::MOV), DestReg)
        .addReg(SrcReg, getKillRegState(KillSrc));
    return;
  }

  llvm_unreachable("Impossible reg-to-reg copy");
}

void V850InstrInfo::storeRegToStackSlot(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator MI, Register SrcReg,
    bool isKill, int FrameIdx, const TargetRegisterClass *RC,
    const TargetRegisterInfo *TRI, Register VReg,
    MachineInstr::MIFlag Flags) const {
  DebugLoc DL;
  if (MI != MBB.end())
    DL = MI->getDebugLoc();
  MachineFunction &MF = *MBB.getParent();
  MachineFrameInfo &MFI = MF.getFrameInfo();

  MachineMemOperand *MMO = MF.getMachineMemOperand(
      MachinePointerInfo::getFixedStack(MF, FrameIdx),
      MachineMemOperand::MOStore, MFI.getObjectSize(FrameIdx),
      MFI.getObjectAlign(FrameIdx));

  if (RC == &V850::GPRRegClass) {
    BuildMI(MBB, MI, DL, get(V850::STW))
        .addReg(SrcReg, getKillRegState(isKill))
        .addFrameIndex(FrameIdx)
        .addImm(0)
        .addMemOperand(MMO);
  } else {
    llvm_unreachable("Cannot store this register to stack slot!");
  }
}

void V850InstrInfo::loadRegFromStackSlot(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator MI, Register DestReg,
    int FrameIdx, const TargetRegisterClass *RC, const TargetRegisterInfo *TRI,
    Register VReg, MachineInstr::MIFlag Flags) const {
  DebugLoc DL;
  if (MI != MBB.end())
    DL = MI->getDebugLoc();
  MachineFunction &MF = *MBB.getParent();
  MachineFrameInfo &MFI = MF.getFrameInfo();

  MachineMemOperand *MMO = MF.getMachineMemOperand(
      MachinePointerInfo::getFixedStack(MF, FrameIdx),
      MachineMemOperand::MOLoad, MFI.getObjectSize(FrameIdx),
      MFI.getObjectAlign(FrameIdx));

  if (RC == &V850::GPRRegClass) {
    BuildMI(MBB, MI, DL, get(V850::LDW))
        .addReg(DestReg, getDefRegState(true))
        .addFrameIndex(FrameIdx)
        .addImm(0)
        .addMemOperand(MMO);
  } else {
    llvm_unreachable("Cannot load this register from stack slot!");
  }
}

unsigned V850InstrInfo::getInstSizeInBytes(const MachineInstr &MI) const {
  const MCInstrDesc &Desc = MI.getDesc();

  switch (Desc.getOpcode()) {
  case TargetOpcode::CFI_INSTRUCTION:
  case TargetOpcode::EH_LABEL:
  case TargetOpcode::IMPLICIT_DEF:
  case TargetOpcode::KILL:
  case TargetOpcode::DBG_VALUE:
    return 0;
  case TargetOpcode::INLINEASM:
  case TargetOpcode::INLINEASM_BR: {
    const MachineFunction *MF = MI.getParent()->getParent();
    const TargetInstrInfo &TII = *MF->getSubtarget().getInstrInfo();
    return TII.getInlineAsmLength(MI.getOperand(0).getSymbolName(),
                                  *MF->getTarget().getMCAsmInfo());
  }
  }

  return Desc.getSize();
}

//===----------------------------------------------------------------------===//
// Branch analysis helpers
//===----------------------------------------------------------------------===//

/// Return true if the given opcode is a conditional branch.
static bool isCondBranchOpcode(unsigned Opc) {
  switch (Opc) {
  case V850::BV:
  case V850::BC:
  case V850::BZ:
  case V850::BNH:
  case V850::BN:
  case V850::BLT:
  case V850::BLE:
  case V850::BNV:
  case V850::BNC:
  case V850::BNZ:
  case V850::BH:
  case V850::BP:
  case V850::BSA:
  case V850::BGE:
  case V850::BGT:
    return true;
  default:
    return false;
  }
}

/// Return the opcode of the branch with the opposite condition.
unsigned V850InstrInfo::getOppositeBranchOpcode(unsigned Opc) const {
  switch (Opc) {
  case V850::BV:   return V850::BNV;
  case V850::BNV:  return V850::BV;
  case V850::BC:   return V850::BNC;
  case V850::BNC:  return V850::BC;
  case V850::BZ:   return V850::BNZ;
  case V850::BNZ:  return V850::BZ;
  case V850::BNH:  return V850::BH;
  case V850::BH:   return V850::BNH;
  case V850::BN:   return V850::BP;
  case V850::BP:   return V850::BN;
  case V850::BLT:  return V850::BGE;
  case V850::BGE:  return V850::BLT;
  case V850::BLE:  return V850::BGT;
  case V850::BGT:  return V850::BLE;
  case V850::BSA:  return 0;  // No opposite for saturated
  default:
    return 0;
  }
}

bool V850InstrInfo::analyzeBranch(MachineBasicBlock &MBB,
                                  MachineBasicBlock *&TBB,
                                  MachineBasicBlock *&FBB,
                                  SmallVectorImpl<MachineOperand> &Cond,
                                  bool AllowModify) const {
  TBB = nullptr;
  FBB = nullptr;
  Cond.clear();

  // Start from the bottom of the block and work up
  MachineBasicBlock::iterator I = MBB.end();
  MachineBasicBlock::iterator UnCondBrIter = MBB.end();

  while (I != MBB.begin()) {
    --I;
    if (I->isDebugInstr())
      continue;

    // Not a terminator
    if (!isUnpredicatedTerminator(*I))
      break;

    // Cannot handle indirect branches
    if (I->getOpcode() == V850::JMP)
      return true;

    // Handle unconditional branches (JR)
    if (I->getOpcode() == V850::JR) {
      // If we see another unconditional branch, the first one is dead
      if (UnCondBrIter != MBB.end() && AllowModify) {
        UnCondBrIter->eraseFromParent();
        UnCondBrIter = MBB.end();
      }

      UnCondBrIter = I;
      TBB = I->getOperand(0).getMBB();
      continue;
    }

    // Handle conditional branches
    if (isCondBranchOpcode(I->getOpcode())) {
      // Already have a conditional branch - we can only handle one
      if (!Cond.empty())
        return true;

      MachineBasicBlock *CondDest = I->getOperand(0).getMBB();

      // If we have an unconditional branch after this, it's the false target
      if (UnCondBrIter != MBB.end()) {
        FBB = TBB;
        TBB = CondDest;
      } else {
        TBB = CondDest;
      }

      // Record the condition (branch opcode)
      Cond.push_back(MachineOperand::CreateImm(I->getOpcode()));
      continue;
    }

    // Unknown terminator
    return true;
  }

  // Optimize away unconditional branch to fallthrough
  if (AllowModify && UnCondBrIter != MBB.end() && Cond.empty()) {
    if (MBB.isLayoutSuccessor(TBB)) {
      UnCondBrIter->eraseFromParent();
      TBB = nullptr;
      return false;
    }
  }

  return false;
}

unsigned V850InstrInfo::removeBranch(MachineBasicBlock &MBB,
                                     int *BytesRemoved) const {
  assert(!BytesRemoved && "code size not handled");

  MachineBasicBlock::iterator I = MBB.end();
  unsigned Count = 0;

  while (I != MBB.begin()) {
    --I;
    if (I->isDebugInstr())
      continue;

    // Only remove conditional and unconditional branches
    if (I->getOpcode() != V850::JR && !isCondBranchOpcode(I->getOpcode()))
      break;

    // Remove the branch
    I->eraseFromParent();
    I = MBB.end();
    ++Count;
  }

  return Count;
}

unsigned V850InstrInfo::insertBranch(MachineBasicBlock &MBB,
                                     MachineBasicBlock *TBB,
                                     MachineBasicBlock *FBB,
                                     ArrayRef<MachineOperand> Cond,
                                     const DebugLoc &DL,
                                     int *BytesAdded) const {
  assert(TBB && "insertBranch must not be told to insert a fallthrough");
  assert(!BytesAdded && "code size not handled");

  if (Cond.empty()) {
    // Unconditional branch
    assert(!FBB && "Unconditional branch with multiple successors!");
    BuildMI(&MBB, DL, get(V850::JR)).addMBB(TBB);
    return 1;
  }

  // Conditional branch
  assert(Cond.size() == 1 && "V850 branch conditions have one component");
  unsigned Opc = Cond[0].getImm();
  BuildMI(&MBB, DL, get(Opc)).addMBB(TBB);

  if (!FBB) {
    // One-way conditional branch
    return 1;
  }

  // Two-way conditional branch: conditional + unconditional fallback
  BuildMI(&MBB, DL, get(V850::JR)).addMBB(FBB);
  return 2;
}

bool V850InstrInfo::reverseBranchCondition(
    SmallVectorImpl<MachineOperand> &Cond) const {
  assert(Cond.size() == 1 && "V850 branch conditions have one component");

  unsigned Opc = Cond[0].getImm();
  unsigned NewOpc = getOppositeBranchOpcode(Opc);
  if (NewOpc == 0)
    return true;  // Cannot reverse

  Cond[0].setImm(NewOpc);
  return false;
}

//===----------------------------------------------------------------------===//
// Branch relaxation support
//===----------------------------------------------------------------------===//

bool V850InstrInfo::isBranchOffsetInRange(unsigned BranchOpc,
                                          int64_t BrOffset) const {
  switch (BranchOpc) {
  default:
    llvm_unreachable("Unexpected opcode!");

  // Conditional branches use 9-bit displacement (disp9)
  // Range: -256 to +254 bytes (bit 0 is always 0)
  case V850::BV:
  case V850::BC:
  case V850::BZ:
  case V850::BNH:
  case V850::BN:
  case V850::BR:
  case V850::BLT:
  case V850::BLE:
  case V850::BNV:
  case V850::BNC:
  case V850::BNZ:
  case V850::BH:
  case V850::BP:
  case V850::BSA:
  case V850::BGE:
  case V850::BGT:
    return isInt<9>(BrOffset) && (BrOffset & 1) == 0;

  // JR uses 22-bit displacement (disp22)
  // Range: approximately ±2MB
  case V850::JR:
    return isInt<22>(BrOffset) && (BrOffset & 1) == 0;
  }
}

MachineBasicBlock *
V850InstrInfo::getBranchDestBlock(const MachineInstr &MI) const {
  switch (MI.getOpcode()) {
  default:
    llvm_unreachable("Unexpected opcode!");
  case V850::BV:
  case V850::BC:
  case V850::BZ:
  case V850::BNH:
  case V850::BN:
  case V850::BR:
  case V850::BLT:
  case V850::BLE:
  case V850::BNV:
  case V850::BNC:
  case V850::BNZ:
  case V850::BH:
  case V850::BP:
  case V850::BSA:
  case V850::BGE:
  case V850::BGT:
  case V850::JR:
    return MI.getOperand(0).getMBB();
  }
}

void V850InstrInfo::insertIndirectBranch(MachineBasicBlock &MBB,
                                         MachineBasicBlock &NewDestBB,
                                         MachineBasicBlock &RestoreBB,
                                         const DebugLoc &DL, int64_t BrOffset,
                                         RegScavenger *RS) const {
  // V850 JR instruction has a 22-bit range (±2MB), which is sufficient
  // for most use cases. If we ever need to go beyond that, we would need
  // to use an indirect jump through a register.
  //
  // For branch relaxation, we simply insert a JR instruction which has
  // a much larger range than conditional branches.
  assert(llvm::isInt<22>(BrOffset) && "Branch offset out of range for JR");

  BuildMI(&MBB, DL, get(V850::JR)).addMBB(&NewDestBB);
}
