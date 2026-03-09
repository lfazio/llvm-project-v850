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
#include "clang/Basic/Builtins.h"
#include "clang/Basic/Diagnostic.h"
#include "clang/Basic/MacroBuilder.h"
#include "clang/Basic/TargetBuiltins.h"

using namespace clang;
using namespace clang::targets;

static constexpr int NumBuiltins =
    V850::LastTSBuiltin - Builtin::FirstTSBuiltin;

static constexpr llvm::StringTable BuiltinStrings =
    CLANG_BUILTIN_STR_TABLE_START
#define BUILTIN CLANG_BUILTIN_STR_TABLE
#define TARGET_BUILTIN CLANG_TARGET_BUILTIN_STR_TABLE
#include "clang/Basic/BuiltinsV850.def"
    ;

static constexpr auto BuiltinInfos = Builtin::MakeInfos<NumBuiltins>({
#define BUILTIN CLANG_BUILTIN_ENTRY
#define TARGET_BUILTIN CLANG_TARGET_BUILTIN_ENTRY
#include "clang/Basic/BuiltinsV850.def"
});

const char *const V850TargetInfo::GCCRegNames[] = {
    "r0",  "r1",  "r2",  "r3",  "r4",  "r5",  "r6",  "r7",  "r8",  "r9",  "r10",
    "r11", "r12", "r13", "r14", "r15", "r16", "r17", "r18", "r19", "r20", "r21",
    "r22", "r23", "r24", "r25", "r26", "r27", "r28", "r29", "r30", "r31"};

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
  case CK_V850ES:
    Builder.defineMacro("__v850e__");
    Builder.defineMacro("__v850es__");
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
  case CK_V850E2V3:
    Builder.defineMacro("__v850e__");
    Builder.defineMacro("__v850e2__");
    Builder.defineMacro("__v850e2v3__");
    Builder.defineMacro("__v850e3__");
    break;
  case CK_V850E3:
    Builder.defineMacro("__v850e__");
    Builder.defineMacro("__v850e2__");
    Builder.defineMacro("__v850e3__");
    break;
  case CK_RH850G3M:
    Builder.defineMacro("__v850e__");
    Builder.defineMacro("__v850e2__");
    Builder.defineMacro("__v850e2m__");
    Builder.defineMacro("__rh850__");
    Builder.defineMacro("__rh850g3m__");
    break;
  case CK_RH850G3MH:
    Builder.defineMacro("__v850e__");
    Builder.defineMacro("__v850e2__");
    Builder.defineMacro("__v850e2m__");
    Builder.defineMacro("__rh850__");
    Builder.defineMacro("__rh850g3m__");
    Builder.defineMacro("__rh850g3mh__");
    break;
  case CK_RH850G4MH:
    Builder.defineMacro("__v850e__");
    Builder.defineMacro("__v850e2__");
    Builder.defineMacro("__v850e2m__");
    Builder.defineMacro("__rh850__");
    Builder.defineMacro("__rh850g3m__");
    Builder.defineMacro("__rh850g3mh__");
    Builder.defineMacro("__rh850g4mh__");
    break;
  case CK_RH850G4MH2:
    Builder.defineMacro("__v850e__");
    Builder.defineMacro("__v850e2__");
    Builder.defineMacro("__v850e2m__");
    Builder.defineMacro("__rh850__");
    Builder.defineMacro("__rh850g3m__");
    Builder.defineMacro("__rh850g3mh__");
    Builder.defineMacro("__rh850g4mh__");
    Builder.defineMacro("__rh850g4mh2__");
    break;
  default:
    break;
  }

  // Define FPU macros when hardware FPU is used (not soft-float)
  if (HasFPU && !SoftFloat) {
    Builder.defineMacro("__V850_FPU__");

    // __V850_FP__ indicates floating-point hardware support
    // Bit 1 = single precision (32-bit)
    // Bit 2 = double precision (64-bit)
    // V850E2M FPU supports both single and double precision
    Builder.defineMacro("__V850_FP__", "0x6"); // SP + DP

    // FMA support - V850E2M has MADDF.S/MSUBF.S instructions
    Builder.defineMacro("__V850_FEATURE_FMA__", "1");

    // Hardware square root - V850E2M has SQRTF.S/SQRTF.D
    Builder.defineMacro("__V850_FEATURE_SQRT__", "1");

    // Hardware min/max - V850E2M has MINF.S/MAXF.S
    Builder.defineMacro("__V850_FEATURE_MINMAX__", "1");
  }

  // Indicate soft-float mode
  if (SoftFloat)
    Builder.defineMacro("__V850_SOFT_FLOAT__");
}

bool V850TargetInfo::isValidCPUName(StringRef Name) const {
  return llvm::StringSwitch<bool>(Name)
      .Case("v850", true)
      .Case("v850e1", true)
      .Case("v850es", true)
      .Case("v850e2", true)
      .Case("v850e2m", true)
      .Case("v850e2v3", true)
      .Case("v850e3", true)
      .Case("g3m", true)
      .Case("g3mh", true)
      .Case("g4mh", true)
      .Case("g4mh2", true)
      .Default(false);
}

void V850TargetInfo::fillValidCPUList(
    SmallVectorImpl<StringRef> &Values) const {
  Values.emplace_back("v850");
  Values.emplace_back("v850e1");
  Values.emplace_back("v850es");
  Values.emplace_back("v850e2");
  Values.emplace_back("v850e2m");
  Values.emplace_back("v850e2v3");
  Values.emplace_back("v850e3");
  Values.emplace_back("g3m");
  Values.emplace_back("g3mh");
  Values.emplace_back("g4mh");
  Values.emplace_back("g4mh2");
}

bool V850TargetInfo::setCPU(const std::string &Name) {
  CPU = llvm::StringSwitch<CPUKind>(Name)
            .Case("v850", CK_V850)
            .Case("v850e1", CK_V850E1)
            .Case("v850es", CK_V850ES)
            .Case("v850e2", CK_V850E2)
            .Case("v850e2m", CK_V850E2M)
            .Case("v850e2v3", CK_V850E2V3)
            .Case("v850e3", CK_V850E3)
            .Case("g3m", CK_RH850G3M)
            .Case("g3mh", CK_RH850G3MH)
            .Case("g4mh", CK_RH850G4MH)
            .Case("g4mh2", CK_RH850G4MH2)
            .Default(CK_NONE);

  // V850E2M and later have FPU by default (includes RH850 variants)
  HasFPU = (CPU >= CK_V850E2M);

  // V850E2M has CAXI (compare-and-exchange) for 32-bit atomics.
  // V850 is single-core in-order, so aligned loads/stores up to 32-bit
  // are inherently atomic.
  if (CPU >= CK_V850E2M) {
    MaxAtomicInlineWidth = 32;
    MaxAtomicPromoteWidth = 32;
  }

  return CPU != CK_NONE;
}

bool V850TargetInfo::initFeatureMap(
    llvm::StringMap<bool> &Features, DiagnosticsEngine &Diags, StringRef CPU,
    const std::vector<std::string> &FeaturesVec) const {
  // Enable features based on CPU variant
  // Features are cumulative: g3mh includes g3m includes v850e2m includes v850e2
  // includes v850e1
  CPUKind CpuKind = llvm::StringSwitch<CPUKind>(CPU)
                        .Case("v850", CK_V850)
                        .Case("v850e1", CK_V850E1)
                        .Case("v850es", CK_V850ES)
                        .Case("v850e2", CK_V850E2)
                        .Case("v850e2m", CK_V850E2M)
                        .Case("v850e2v3", CK_V850E2V3)
                        .Case("v850e3", CK_V850E3)
                        .Case("g3m", CK_RH850G3M)
                        .Case("g3mh", CK_RH850G3MH)
                        .Case("g4mh", CK_RH850G4MH)
                        .Case("g4mh2", CK_RH850G4MH2)
                        .Default(CK_V850);

  // V850E1 and later (including V850ES)
  if (CpuKind >= CK_V850E1)
    Features["v850e1"] = true;

  // V850E2 and later
  if (CpuKind >= CK_V850E2)
    Features["v850e2"] = true;

  // V850E2M and later (includes FPU by default)
  if (CpuKind >= CK_V850E2M) {
    Features["v850e2m"] = true;
    Features["v850fpu"] = true;
  }

  // V850E3 and later
  if (CpuKind >= CK_V850E3)
    Features["v850e3"] = true;

  // RH850G3M and later
  if (CpuKind >= CK_RH850G3M)
    Features["rh850g3m"] = true;

  // FPIPR register exists on G3M but is removed on G3MH+
  // (FPINT exception replaces FPP/FPI, FPIPR no longer needed)
  if (CpuKind >= CK_RH850G3M && CpuKind < CK_RH850G3MH)
    Features["v850-fpipr"] = true;

  // RH850G3MH and later
  if (CpuKind >= CK_RH850G3MH)
    Features["rh850g3mh"] = true;

  // RH850G4MH and later
  if (CpuKind >= CK_RH850G4MH)
    Features["rh850g4mh"] = true;

  // RH850G4MH2 and later
  if (CpuKind >= CK_RH850G4MH2)
    Features["rh850g4mh2"] = true;

  return TargetInfo::initFeatureMap(Features, Diags, CPU, FeaturesVec);
}

bool V850TargetInfo::handleTargetFeatures(std::vector<std::string> &Features,
                                          DiagnosticsEngine &Diags) {
  for (const auto &Feature : Features) {
    if (Feature == "+v850fpu")
      HasFPU = true;
    else if (Feature == "-v850fpu")
      HasFPU = false;
    else if (Feature == "+soft-float")
      SoftFloat = true;
    else if (Feature == "-soft-float")
      SoftFloat = false;
  }
  return true;
}

llvm::SmallVector<Builtin::InfosShard>
V850TargetInfo::getTargetBuiltins() const {
  return {{&BuiltinStrings, BuiltinInfos}};
}
