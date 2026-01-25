//===-- V850MCCodeEmitter.cpp - Convert V850 code to machine code ---------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements the V850MCCodeEmitter class.
//
//===----------------------------------------------------------------------===//

#include "V850MCTargetDesc.h"
#include "llvm/MC/MCCodeEmitter.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCFixup.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/EndianStream.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

#define DEBUG_TYPE "mccodeemitter"

namespace {

class V850MCCodeEmitter : public MCCodeEmitter {
  V850MCCodeEmitter(const V850MCCodeEmitter &) = delete;
  void operator=(const V850MCCodeEmitter &) = delete;
  MCContext &Ctx;
  MCInstrInfo const &MCII;

public:
  V850MCCodeEmitter(MCContext &Ctx, MCInstrInfo const &MCII)
      : Ctx(Ctx), MCII(MCII) {}

  void encodeInstruction(const MCInst &MI, SmallVectorImpl<char> &CB,
                         SmallVectorImpl<MCFixup> &Fixups,
                         const MCSubtargetInfo &STI) const override;

  ~V850MCCodeEmitter() override = default;

  // TableGen'erated function for getting the binary encoding for an instruction
  uint64_t getBinaryCodeForInstr(const MCInst &MI,
                                 SmallVectorImpl<MCFixup> &Fixups,
                                 const MCSubtargetInfo &STI) const;

  // Return binary encoding of operand
  unsigned getMachineOpValue(const MCInst &MI, const MCOperand &MO,
                             SmallVectorImpl<MCFixup> &Fixups,
                             const MCSubtargetInfo &STI) const;

  // Get encoding for 9-bit branch target
  unsigned getBranchTarget9OpValue(const MCInst &MI, unsigned OpNo,
                                   SmallVectorImpl<MCFixup> &Fixups,
                                   const MCSubtargetInfo &STI) const;

  // Get encoding for 22-bit branch target
  unsigned getBranchTarget22OpValue(const MCInst &MI, unsigned OpNo,
                                    SmallVectorImpl<MCFixup> &Fixups,
                                    const MCSubtargetInfo &STI) const;

  // Get encoding for 32-bit branch target (V850E2+)
  unsigned getBranchTarget32OpValue(const MCInst &MI, unsigned OpNo,
                                    SmallVectorImpl<MCFixup> &Fixups,
                                    const MCSubtargetInfo &STI) const;
};

} // end anonymous namespace

void V850MCCodeEmitter::encodeInstruction(const MCInst &MI,
                                          SmallVectorImpl<char> &CB,
                                          SmallVectorImpl<MCFixup> &Fixups,
                                          const MCSubtargetInfo &STI) const {
  const MCInstrDesc &Desc = MCII.get(MI.getOpcode());
  unsigned Size = Desc.getSize();

  uint64_t Binary = getBinaryCodeForInstr(MI, Fixups, STI);

  // V850 is little-endian
  if (Size == 2) {
    support::endian::write<uint16_t>(CB, Binary, llvm::endianness::little);
  } else if (Size == 4) {
    // 32-bit instructions: emit first halfword, then second halfword
    support::endian::write<uint16_t>(CB, Binary & 0xFFFF, llvm::endianness::little);
    support::endian::write<uint16_t>(CB, (Binary >> 16) & 0xFFFF, llvm::endianness::little);
  } else if (Size == 6) {
    // 48-bit instructions: emit three halfwords
    support::endian::write<uint16_t>(CB, Binary & 0xFFFF, llvm::endianness::little);
    support::endian::write<uint16_t>(CB, (Binary >> 16) & 0xFFFF, llvm::endianness::little);
    support::endian::write<uint16_t>(CB, (Binary >> 32) & 0xFFFF, llvm::endianness::little);
  }
}

unsigned V850MCCodeEmitter::getMachineOpValue(const MCInst &MI,
                                              const MCOperand &MO,
                                              SmallVectorImpl<MCFixup> &Fixups,
                                              const MCSubtargetInfo &STI) const {
  if (MO.isReg())
    return Ctx.getRegisterInfo()->getEncodingValue(MO.getReg());

  if (MO.isImm())
    return static_cast<unsigned>(MO.getImm());

  // Handle expression operand - add fixup and return 0 as placeholder
  assert(MO.isExpr() && "Expected expression operand");
  Fixups.push_back(MCFixup::create(0, MO.getExpr(),
                                   static_cast<MCFixupKind>(V850::fixup_v850_32),
                                   /*PCRel=*/false));
  return 0;
}

unsigned V850MCCodeEmitter::getBranchTarget9OpValue(
    const MCInst &MI, unsigned OpNo, SmallVectorImpl<MCFixup> &Fixups,
    const MCSubtargetInfo &STI) const {
  const MCOperand &MO = MI.getOperand(OpNo);
  if (MO.isImm())
    return MO.getImm() >> 1; // Shift right by 1 (bit 0 is implicit 0)

  // Handle expression operand - add PC-relative fixup
  assert(MO.isExpr() && "Expected expression operand");
  Fixups.push_back(MCFixup::create(0, MO.getExpr(),
                                   static_cast<MCFixupKind>(V850::fixup_v850_9_pcrel),
                                   /*PCRel=*/true));
  return 0;
}

unsigned V850MCCodeEmitter::getBranchTarget22OpValue(
    const MCInst &MI, unsigned OpNo, SmallVectorImpl<MCFixup> &Fixups,
    const MCSubtargetInfo &STI) const {
  const MCOperand &MO = MI.getOperand(OpNo);
  if (MO.isImm())
    return MO.getImm() >> 1; // Shift right by 1 (bit 0 is implicit 0)

  // Handle expression operand - add PC-relative fixup for JARL/JR
  assert(MO.isExpr() && "Expected expression operand");
  Fixups.push_back(MCFixup::create(0, MO.getExpr(),
                                   static_cast<MCFixupKind>(V850::fixup_v850_22_pcrel),
                                   /*PCRel=*/true));
  return 0;
}

unsigned V850MCCodeEmitter::getBranchTarget32OpValue(
    const MCInst &MI, unsigned OpNo, SmallVectorImpl<MCFixup> &Fixups,
    const MCSubtargetInfo &STI) const {
  const MCOperand &MO = MI.getOperand(OpNo);
  if (MO.isImm())
    return MO.getImm() >> 1; // Shift right by 1 (bit 0 is implicit 0)

  // Handle expression operand - add PC-relative fixup for 32-bit branch
  assert(MO.isExpr() && "Expected expression operand");
  Fixups.push_back(MCFixup::create(0, MO.getExpr(),
                                   static_cast<MCFixupKind>(V850::fixup_v850_32),
                                   /*PCRel=*/true));
  return 0;
}

#include "V850GenMCCodeEmitter.inc"

MCCodeEmitter *llvm::createV850MCCodeEmitter(const MCInstrInfo &MCII,
                                             MCContext &Ctx) {
  return new V850MCCodeEmitter(Ctx, MCII);
}
