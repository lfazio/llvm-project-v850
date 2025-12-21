//===-- V850MCAsmInfo.cpp - V850 Asm Properties ---------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the declarations of the V850MCAsmInfo properties.
//
//===----------------------------------------------------------------------===//

#include "V850MCAsmInfo.h"
#include "llvm/MC/MCTargetOptions.h"
#include "llvm/TargetParser/Triple.h"

using namespace llvm;

void V850MCAsmInfo::anchor() {}

V850MCAsmInfo::V850MCAsmInfo(const Triple & /*TheTriple*/,
                             const MCTargetOptions & /*Options*/) {
  // V850 is little-endian
  IsLittleEndian = true;

  // Use standard ELF section directive
  UsesELFSectionDirectiveForBSS = true;

  // Comment string
  CommentString = ";";

  // Private label prefix
  PrivateGlobalPrefix = ".L";
  PrivateLabelPrefix = ".L";

  // Instruction alignment (16-bit minimum)
  MinInstAlignment = 2;

  // Support debugging information
  SupportsDebugInformation = true;

  // Exception handling
  ExceptionsType = ExceptionHandling::DwarfCFI;

  // Data directives
  Data8bitsDirective = "\t.byte\t";
  Data16bitsDirective = "\t.hword\t";
  Data32bitsDirective = "\t.word\t";
}
