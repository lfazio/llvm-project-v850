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
#include "V850.h"
#include "TargetInfo/V850TargetInfo.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/CodeGen/TargetPassConfig.h"
#include "llvm/MC/TargetRegistry.h"

using namespace llvm;

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void LLVMInitializeV850Target() {
  // Register the target.
  RegisterTargetMachine<V850TargetMachine> X(getTheV850Target());
}

static std::string computeDataLayout(const Triple &TT) {
  // V850 is little-endian, 32-bit pointers and integers
  // e = little endian
  // p:32:32 = 32-bit pointers with 32-bit alignment
  // i32:32 = 32-bit integers with 32-bit alignment
  // n32 = native integer width is 32-bit
  // S32 = stack natural alignment is 32-bit
  return "e-p:32:32-i32:32-n32-S32";
}

V850TargetMachine::V850TargetMachine(const Target &T, const Triple &TT,
                                     StringRef CPU, StringRef FS,
                                     const TargetOptions &Options,
                                     std::optional<Reloc::Model> RM,
                                     std::optional<CodeModel::Model> CM,
                                     CodeGenOptLevel OL, bool JIT)
    : CodeGenTargetMachineImpl(T, computeDataLayout(TT), TT, CPU, FS, Options,
                               RM.value_or(Reloc::Static),
                               CM.value_or(CodeModel::Small), OL),
      TLOF(std::make_unique<TargetLoweringObjectFileELF>()) {
  initAsmInfo();
}

namespace {

class V850PassConfig : public TargetPassConfig {
public:
  V850PassConfig(V850TargetMachine &TM, PassManagerBase &PM)
      : TargetPassConfig(TM, PM) {}

  V850TargetMachine &getV850TargetMachine() const {
    return getTM<V850TargetMachine>();
  }
};

} // end anonymous namespace

TargetPassConfig *V850TargetMachine::createPassConfig(PassManagerBase &PM) {
  return new V850PassConfig(*this, PM);
}
