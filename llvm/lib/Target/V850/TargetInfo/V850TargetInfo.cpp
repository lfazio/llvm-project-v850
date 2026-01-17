//===-- V850TargetInfo.cpp - V850 Target Implementation ------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "TargetInfo/V850TargetInfo.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Compiler.h"

using namespace llvm;

Target &llvm::getTheV850Target() {
  static Target TheV850Target;
  return TheV850Target;
}

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void
LLVMInitializeV850TargetInfo() {
  RegisterTarget<Triple::v850> X(getTheV850Target(), "v850", "NEC V850",
                                 "V850");
}
