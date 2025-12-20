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
    // TODO: Implement proper relocation type mapping
    return ELF::R_V850_NONE;
  }
};

} // end anonymous namespace

std::unique_ptr<MCObjectTargetWriter>
llvm::createV850ELFObjectWriter(uint8_t OSABI) {
  return std::make_unique<V850ELFObjectWriter>(OSABI);
}
