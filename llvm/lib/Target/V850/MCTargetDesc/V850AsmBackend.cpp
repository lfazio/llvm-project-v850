//===-- V850AsmBackend.cpp - V850 Assembler Backend -----------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements the V850AsmBackend class.
//
//===----------------------------------------------------------------------===//

#include "V850MCTargetDesc.h"
#include "llvm/MC/MCAsmBackend.h"
#include "llvm/MC/MCAssembler.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCDirectives.h"
#include "llvm/MC/MCELFObjectWriter.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCObjectWriter.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/MCTargetOptions.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/EndianStream.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace {

class V850AsmBackend : public MCAsmBackend {
  const MCSubtargetInfo &STI;
  uint8_t OSABI;
  const MCTargetOptions &TargetOptions;

public:
  V850AsmBackend(const MCSubtargetInfo &STI, uint8_t OSABI,
                 const MCTargetOptions &Options)
      : MCAsmBackend(llvm::endianness::little), STI(STI), OSABI(OSABI),
        TargetOptions(Options) {}
  ~V850AsmBackend() override = default;

  MCFixupKindInfo getFixupKindInfo(MCFixupKind Kind) const override {
    const static MCFixupKindInfo Infos[V850::NumTargetFixupKinds] = {
        // name                    offset  bits  flags
        // PC-relative fixups use full instruction width because displacement
        // bits are scattered across the encoding (not contiguous).
        {"fixup_v850_9_pcrel", 0, 16, 0},  {"fixup_v850_16_pcrel", 0, 16, 0},
        {"fixup_v850_17_pcrel", 0, 32, 0}, {"fixup_v850_22_pcrel", 0, 32, 0},
        {"fixup_v850_16", 16, 16, 0},      {"fixup_v850_32", 0, 32, 0},
        {"fixup_v850_hi16", 16, 16, 0},    {"fixup_v850_lo16", 16, 16, 0},
        {"fixup_v850_sda_16", 16, 16, 0},
    };

    if (Kind < FirstTargetFixupKind)
      return MCAsmBackend::getFixupKindInfo(Kind);

    assert(unsigned(Kind - FirstTargetFixupKind) < V850::NumTargetFixupKinds &&
           "Invalid kind!");
    return Infos[Kind - FirstTargetFixupKind];
  }

  void applyFixup(const MCFragment &F, const MCFixup &Fixup,
                  const MCValue &Target, MutableArrayRef<char> Data,
                  uint64_t Value, bool IsResolved) override {
    // Let the base class handle relocation generation
    maybeAddReloc(F, Fixup, Target, Value, IsResolved);

    MCFixupKind Kind = Fixup.getKind();
    if (Kind >= FirstTargetFixupKind)
      Kind = static_cast<MCFixupKind>(unsigned(Kind - FirstTargetFixupKind));

    unsigned Offset = Fixup.getOffset();
    unsigned NumBytes = 0;

    switch (static_cast<unsigned>(Fixup.getKind())) {
    default:
      llvm_unreachable("Unknown fixup kind!");
    case FK_Data_1:
      NumBytes = 1;
      break;
    case FK_Data_2:
      NumBytes = 2;
      break;
    case FK_Data_4:
      NumBytes = 4;
      break;
    case V850::fixup_v850_9_pcrel:
      // 9-bit PC-relative for conditional branches
      // Format III: disp9 = {Inst[15:11], Inst[6:4], 0}
      // Value is shifted right by 1 (bit 0 always 0)
      Value >>= 1;
      // Upper 5 bits go to [15:11], lower 3 bits to [6:4]
      Data[Offset] = (Data[Offset] & 0x8F) | ((Value & 0x07) << 4);
      Data[Offset + 1] = (Data[Offset + 1] & 0x07) | ((Value >> 3) & 0x1F) << 3;
      return;
    case V850::fixup_v850_16_pcrel:
      // 16-bit PC-relative for LOOP instruction
      // Value is shifted right by 1 (bit 0 always 0)
      Value >>= 1;
      // 16-bit displacement in second halfword (bits 31-16)
      support::endian::write16le(&Data[Offset + 2], Value & 0xFFFF);
      return;
    case V850::fixup_v850_17_pcrel:
      // 17-bit PC-relative for Bcond disp17 (RH850G3M+)
      // Format: 00000111111DCCCC ddddddddddddddd1
      // D = sign bit of half-displacement, d = lower 15 bits, bit 0 fixed at 1
      // Value is shifted right by 1 to get half-displacement
      Value >>= 1;
      // Sign bit (bit 15) goes to first halfword bit 4
      Data[Offset] = (Data[Offset] & 0xEF) | ((Value >> 11) & 0x10);
      // Lower 15 bits go to second halfword bits 15-1, bit 0 is fixed at 1
      support::endian::write16le(&Data[Offset + 2],
                                 ((Value & 0x7FFF) << 1) | 1);
      return;
    case V850::fixup_v850_22_pcrel:
      // 22-bit PC-relative for JR/JARL
      // Value is shifted right by 1
      Value >>= 1;
      // Split across 32-bit instruction
      Data[Offset] = (Data[Offset] & 0xC0) | (Value & 0x3F);
      Data[Offset + 2] = (Value >> 6) & 0xFF;
      Data[Offset + 3] = (Value >> 14) & 0xFF;
      return;
    case V850::fixup_v850_16:
    case V850::fixup_v850_lo16:
    case V850::fixup_v850_sda_16:
      // 16-bit value in second halfword (GP-relative for SDA)
      support::endian::write16le(&Data[Offset + 2], Value & 0xFFFF);
      return;
    case V850::fixup_v850_hi16:
      // High 16 bits in second halfword
      support::endian::write16le(&Data[Offset + 2], (Value >> 16) & 0xFFFF);
      return;
    case V850::fixup_v850_32:
      NumBytes = 4;
      break;
    }

    // Write the value in little-endian
    for (unsigned i = 0; i != NumBytes; ++i) {
      Data[Offset + i] |= uint8_t((Value >> (i * 8)) & 0xFF);
    }
  }

  bool mayNeedRelaxation(unsigned Opcode, ArrayRef<MCOperand> Operands,
                         const MCSubtargetInfo &STI) const override {
    return false;
  }

  void relaxInstruction(MCInst &Inst,
                        const MCSubtargetInfo &STI) const override {
    llvm_unreachable("V850AsmBackend::relaxInstruction() unimplemented");
  }

  bool writeNopData(raw_ostream &OS, uint64_t Count,
                    const MCSubtargetInfo *STI) const override {
    // V850 NOP is 0x0000 (2 bytes)
    if ((Count % 2) != 0)
      return false;

    uint64_t NumNops = Count / 2;
    for (uint64_t i = 0; i < NumNops; ++i)
      OS.write("\x00\x00", 2);

    return true;
  }

  std::unique_ptr<MCObjectTargetWriter>
  createObjectTargetWriter() const override {
    return createV850ELFObjectWriter(OSABI);
  }
};

} // end anonymous namespace

MCAsmBackend *llvm::createV850AsmBackend(const Target &T,
                                         const MCSubtargetInfo &STI,
                                         const MCRegisterInfo &MRI,
                                         const MCTargetOptions &Options) {
  const Triple &TT = STI.getTargetTriple();
  uint8_t OSABI = MCELFObjectTargetWriter::getOSABI(TT.getOS());
  return new V850AsmBackend(STI, OSABI, Options);
}
