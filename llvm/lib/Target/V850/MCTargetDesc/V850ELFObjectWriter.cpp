//===-- V850ELFObjectWriter.cpp - V850 ELF Writer -------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements the V850ELFObjectWriter class.
//
//===----------------------------------------------------------------------===//

#include "V850MCTargetDesc.h"
#include "llvm/BinaryFormat/ELF.h"
#include "llvm/MC/MCELFObjectWriter.h"
#include "llvm/MC/MCFixup.h"
#include "llvm/MC/MCObjectWriter.h"
#include "llvm/MC/MCValue.h"
#include "llvm/Support/ErrorHandling.h"

using namespace llvm;

namespace {

class V850ELFObjectWriter : public MCELFObjectTargetWriter {
public:
  V850ELFObjectWriter(uint8_t OSABI)
      : MCELFObjectTargetWriter(/*Is64Bit=*/false, OSABI, ELF::EM_V850,
                                /*HasRelocationAddend=*/true) {}

protected:
  unsigned getRelocType(const MCFixup &Fixup, const MCValue &Target,
                        bool IsPCRel) const override {
    unsigned Kind = Fixup.getKind();

    switch (Kind) {
    default:
      llvm_unreachable("Invalid fixup kind!");
    case FK_Data_1:
      return ELF::R_V850_8;
    case FK_Data_2:
      return ELF::R_V850_16;
    case FK_Data_4:
      return ELF::R_V850_32;
    case V850::fixup_v850_9_pcrel:
      return ELF::R_V850_9_PCREL;
    case V850::fixup_v850_22_pcrel:
      return ELF::R_V850_22_PCREL;
    case V850::fixup_v850_16:
      return ELF::R_V850_16;
    case V850::fixup_v850_32:
      return ELF::R_V850_32;
    case V850::fixup_v850_hi16:
      return ELF::R_V850_HI16;
    case V850::fixup_v850_lo16:
      return ELF::R_V850_LO16;
    case V850::fixup_v850_sda_16:
      return ELF::R_V850_SDA_16_16_OFFSET;
    }
  }
};

} // end anonymous namespace

std::unique_ptr<MCObjectTargetWriter>
llvm::createV850ELFObjectWriter(uint8_t OSABI) {
  return std::make_unique<V850ELFObjectWriter>(OSABI);
}
