//===-- V850MCTargetDesc.cpp - V850 Target Descriptions -------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file provides V850 specific target descriptions.
//
//===----------------------------------------------------------------------===//

#include "V850MCTargetDesc.h"
#include "TargetInfo/V850TargetInfo.h"
#include "V850MCAsmInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Compiler.h"
#include "llvm/TargetParser/Triple.h"

#define GET_REGINFO_MC_DESC
#include "V850GenRegisterInfo.inc"

using namespace llvm;

static MCRegisterInfo *createV850MCRegisterInfo(const Triple & /*TT*/) {
  MCRegisterInfo *X = new MCRegisterInfo();
  InitV850MCRegisterInfo(X, V850::LP);
  return X;
}

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void LLVMInitializeV850TargetMC() {
  Target &T = getTheV850Target();

  // Register the MC asm info.
  RegisterMCAsmInfo<V850MCAsmInfo> X(T);

  // Register the MC register info.
  TargetRegistry::RegisterMCRegInfo(T, createV850MCRegisterInfo);
}
