//===--- V850.cpp - Implement V850 target feature support -----------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements V850 TargetInfo objects.
//
//===----------------------------------------------------------------------===//

#include "V850.h"
#include "clang/Basic/MacroBuilder.h"

using namespace clang;
using namespace clang::targets;

const char *const V850TargetInfo::GCCRegNames[] = {
    "r0",  "r1",  "r2",  "r3",  "r4",  "r5",  "r6",  "r7",
    "r8",  "r9",  "r10", "r11", "r12", "r13", "r14", "r15",
    "r16", "r17", "r18", "r19", "r20", "r21", "r22", "r23",
    "r24", "r25", "r26", "r27", "r28", "r29", "r30", "r31"
};

ArrayRef<const char *> V850TargetInfo::getGCCRegNames() const {
  return llvm::ArrayRef(GCCRegNames);
}

void V850TargetInfo::getTargetDefines(const LangOptions &Opts,
                                       MacroBuilder &Builder) const {
  Builder.defineMacro("__v850__");
  Builder.defineMacro("__V850__");
  Builder.defineMacro("__v850");

  // Define CPU-specific macros
  switch (CPU) {
  case CK_V850E1:
    Builder.defineMacro("__v850e__");
    Builder.defineMacro("__v850e1__");
    break;
  case CK_V850E2:
    Builder.defineMacro("__v850e__");
    Builder.defineMacro("__v850e2__");
    break;
  case CK_V850E2M:
    Builder.defineMacro("__v850e__");
    Builder.defineMacro("__v850e2__");
    Builder.defineMacro("__v850e2m__");
    break;
  case CK_V850E3:
    Builder.defineMacro("__v850e__");
    Builder.defineMacro("__v850e2__");
    Builder.defineMacro("__v850e3__");
    break;
  default:
    break;
  }
}

bool V850TargetInfo::isValidCPUName(StringRef Name) const {
  return llvm::StringSwitch<bool>(Name)
      .Case("v850", true)
      .Case("v850e1", true)
      .Case("v850e2", true)
      .Case("v850e2m", true)
      .Case("v850e3", true)
      .Default(false);
}

void V850TargetInfo::fillValidCPUList(
    SmallVectorImpl<StringRef> &Values) const {
  Values.emplace_back("v850");
  Values.emplace_back("v850e1");
  Values.emplace_back("v850e2");
  Values.emplace_back("v850e2m");
  Values.emplace_back("v850e3");
}

bool V850TargetInfo::setCPU(const std::string &Name) {
  CPU = llvm::StringSwitch<CPUKind>(Name)
            .Case("v850", CK_V850)
            .Case("v850e1", CK_V850E1)
            .Case("v850e2", CK_V850E2)
            .Case("v850e2m", CK_V850E2M)
            .Case("v850e3", CK_V850E3)
            .Default(CK_NONE);
  return CPU != CK_NONE;
}
