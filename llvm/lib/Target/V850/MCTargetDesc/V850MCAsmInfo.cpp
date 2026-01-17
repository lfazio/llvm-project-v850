//===-- V850MCAsmInfo.cpp - V850 asm properties ---------------------------===//
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

V850MCAsmInfo::V850MCAsmInfo(const Triple &TT, const MCTargetOptions &Options) {
  IsLittleEndian = true;
  PrivateGlobalPrefix = ".L";
  PrivateLabelPrefix = ".L";
  CommentString = "#";
  SupportsDebugInformation = true;
  ExceptionsType = ExceptionHandling::DwarfCFI;
  UsesELFSectionDirectiveForBSS = true;
  Data16bitsDirective = "\t.half\t";
  Data32bitsDirective = "\t.word\t";
}
