//===-- V850TargetMachine.cpp - Define TargetMachine for V850 -------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Implements the info about V850 target spec.
//
//===----------------------------------------------------------------------===//

#include "V850TargetMachine.h"
#include "TargetInfo/V850TargetInfo.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Compiler.h"

using namespace llvm;

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void LLVMInitializeV850Target() {
  RegisterTargetMachine<V850TargetMachine> X(getTheV850Target());
}

static std::string computeDataLayout(const Triple &TT) {
  // V850 is little-endian with 32-bit pointers
  // e = little endian
  // p:32:32 = 32-bit pointers with 32-bit alignment
  // i32:32 = 32-bit integers with 32-bit alignment
  // n32 = native integer width is 32-bit
  return "e-p:32:32-i32:32-n32";
}

V850TargetMachine::V850TargetMachine(const Target &T, const Triple &TT,
                                     StringRef CPU, StringRef FS,
                                     const TargetOptions &Options,
                                     std::optional<Reloc::Model> RM,
                                     std::optional<CodeModel::Model> CM,
                                     CodeGenOptLevel OL, bool JIT)
    : CodeGenTargetMachineImpl(T, computeDataLayout(TT), TT, CPU, FS, Options,
                               RM.value_or(Reloc::Static),
                               CM.value_or(CodeModel::Small), OL) {}
