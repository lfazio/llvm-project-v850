//===-- V850InstrInfo.h - V850 Instruction Information ----------*- C++ -*-===//
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

#ifndef LLVM_LIB_TARGET_V850_V850INSTRINFO_H
#define LLVM_LIB_TARGET_V850_V850INSTRINFO_H

#include "V850RegisterInfo.h"
#include "llvm/CodeGen/TargetInstrInfo.h"

#define GET_INSTRINFO_HEADER
#include "V850GenInstrInfo.inc"

namespace llvm {

class V850Subtarget;

class V850InstrInfo : public V850GenInstrInfo {
  const V850RegisterInfo RI;
  virtual void anchor();

public:
  explicit V850InstrInfo(V850Subtarget &STI);

  /// getRegisterInfo - TargetInstrInfo is a superset of MRegister info. As
  /// such, whenever a client has an instance of instruction info, it should
  /// always be able to get register info as well (through this method).
  const V850RegisterInfo &getRegisterInfo() const { return RI; }

  void copyPhysReg(MachineBasicBlock &MBB, MachineBasicBlock::iterator I,
                   const DebugLoc &DL, Register DestReg, Register SrcReg,
                   bool KillSrc, bool RenamableDest = false,
                   bool RenamableSrc = false) const override;

  void storeRegToStackSlot(
      MachineBasicBlock &MBB, MachineBasicBlock::iterator MI, Register SrcReg,
      bool isKill, int FrameIndex, const TargetRegisterClass *RC,
      const TargetRegisterInfo *TRI, Register VReg,
      MachineInstr::MIFlag Flags = MachineInstr::NoFlags) const override;

  void loadRegFromStackSlot(
      MachineBasicBlock &MBB, MachineBasicBlock::iterator MI, Register DestReg,
      int FrameIdx, const TargetRegisterClass *RC,
      const TargetRegisterInfo *TRI, Register VReg,
      MachineInstr::MIFlag Flags = MachineInstr::NoFlags) const override;

  unsigned getInstSizeInBytes(const MachineInstr &MI) const override;

  // Branch analysis
  bool analyzeBranch(MachineBasicBlock &MBB, MachineBasicBlock *&TBB,
                     MachineBasicBlock *&FBB,
                     SmallVectorImpl<MachineOperand> &Cond,
                     bool AllowModify) const override;

  unsigned removeBranch(MachineBasicBlock &MBB,
                        int *BytesRemoved = nullptr) const override;

  unsigned insertBranch(MachineBasicBlock &MBB, MachineBasicBlock *TBB,
                        MachineBasicBlock *FBB, ArrayRef<MachineOperand> Cond,
                        const DebugLoc &DL,
                        int *BytesAdded = nullptr) const override;

  bool
  reverseBranchCondition(SmallVectorImpl<MachineOperand> &Cond) const override;

  // If-conversion support (CMOV)
  bool canInsertSelect(const MachineBasicBlock &MBB,
                       ArrayRef<MachineOperand> Cond, Register DstReg,
                       Register TrueReg, Register FalseReg, int &CondCycles,
                       int &TrueCycles, int &FalseCycles) const override;

  void insertSelect(MachineBasicBlock &MBB, MachineBasicBlock::iterator I,
                    const DebugLoc &DL, Register DstReg,
                    ArrayRef<MachineOperand> Cond, Register TrueReg,
                    Register FalseReg) const override;

  // Branch relaxation support
  bool isBranchOffsetInRange(unsigned BranchOpc,
                             int64_t BrOffset) const override;

  MachineBasicBlock *getBranchDestBlock(const MachineInstr &MI) const override;

  void insertIndirectBranch(MachineBasicBlock &MBB,
                            MachineBasicBlock &NewDestBB,
                            MachineBasicBlock &RestoreBB, const DebugLoc &DL,
                            int64_t BrOffset, RegScavenger *RS) const override;

  /// Return the opcode of the branch with the opposite condition.
  /// Returns 0 if there is no opposite branch opcode.
  unsigned getOppositeBranchOpcode(unsigned Opc) const;

  // Machine outliner support
  bool isFunctionSafeToOutlineFrom(MachineFunction &MF,
                                   bool OutlineFromLinkOnceODRs) const override;

  bool isMBBSafeToOutlineFrom(MachineBasicBlock &MBB,
                              unsigned &Flags) const override;

  bool shouldOutlineFromFunctionByDefault(MachineFunction &MF) const override;

  std::optional<std::unique_ptr<outliner::OutlinedFunction>>
  getOutliningCandidateInfo(
      const MachineModuleInfo &MMI,
      std::vector<outliner::Candidate> &RepeatedSequenceLocs,
      unsigned MinRepeats) const override;

  outliner::InstrType getOutliningTypeImpl(const MachineModuleInfo &MMI,
                                           MachineBasicBlock::iterator &MBBI,
                                           unsigned Flags) const override;

  void buildOutlinedFrame(MachineBasicBlock &MBB, MachineFunction &MF,
                          const outliner::OutlinedFunction &OF) const override;

  MachineBasicBlock::iterator
  insertOutlinedCall(Module &M, MachineBasicBlock &MBB,
                     MachineBasicBlock::iterator &It, MachineFunction &MF,
                     outliner::Candidate &C) const override;
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_V850_V850INSTRINFO_H
