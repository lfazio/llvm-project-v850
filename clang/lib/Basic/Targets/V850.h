//===--- V850.h - Declare V850 target feature support ----------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file declares V850 TargetInfo objects.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_CLANG_LIB_BASIC_TARGETS_V850_H
#define LLVM_CLANG_LIB_BASIC_TARGETS_V850_H

#include "clang/Basic/TargetInfo.h"
#include "clang/Basic/TargetOptions.h"
#include "llvm/Support/Compiler.h"
#include "llvm/TargetParser/Triple.h"

namespace clang {
namespace targets {

class LLVM_LIBRARY_VISIBILITY V850TargetInfo : public TargetInfo {
  static const char *const GCCRegNames[];

  enum CPUKind {
    CK_NONE,
    CK_V850,
    CK_V850E1,
    CK_V850ES,  // V850ES has same ISA as V850E1
    CK_V850E2,
    CK_V850E2M,
    CK_V850E3,
  } CPU = CK_V850;

public:
  V850TargetInfo(const llvm::Triple &Triple, const TargetOptions &)
      : TargetInfo(Triple) {
    // V850 is a 32-bit architecture
    TLSSupported = false;
    IntWidth = 32;
    IntAlign = 32;
    LongWidth = 32;
    LongAlign = 32;
    LongLongWidth = 64;
    LongLongAlign = 32;
    FloatWidth = 32;
    FloatAlign = 32;
    DoubleWidth = 64;
    DoubleAlign = 32;
    LongDoubleWidth = 64;
    LongDoubleAlign = 32;
    PointerWidth = 32;
    PointerAlign = 32;
    SuitableAlign = 32;
    SizeType = UnsignedInt;
    IntMaxType = SignedLongLong;
    IntPtrType = SignedInt;
    PtrDiffType = SignedInt;
    SigAtomicType = SignedInt;
    // V850 is little-endian
    // e = little endian
    // m:e = ELF mangling
    // p:32:32 = 32-bit pointers with 32-bit alignment
    // i64:32 = 64-bit integers with 32-bit alignment
    // f64:32 = 64-bit floats with 32-bit alignment
    // a:0:32 = aggregates with 32-bit alignment
    // n32 = native integer width is 32-bit
    // S32 = stack has 32-bit alignment
    resetDataLayout("e-m:e-p:32:32-i64:32-f64:32-a:0:32-n32-S32");
  }

  void getTargetDefines(const LangOptions &Opts,
                        MacroBuilder &Builder) const override;

  bool isValidCPUName(StringRef Name) const override;
  void fillValidCPUList(SmallVectorImpl<StringRef> &Values) const override;
  bool setCPU(const std::string &Name) override;

  llvm::SmallVector<Builtin::InfosShard> getTargetBuiltins() const override {
    return {};
  }

  bool allowsLargerPreferedTypeAlignment() const override { return false; }

  bool hasFeature(StringRef Feature) const override {
    return llvm::StringSwitch<bool>(Feature)
        .Case("v850", true)
        .Case("v850e", CPU >= CK_V850E1)
        .Case("v850e1", CPU >= CK_V850E1)
        .Case("v850es", CPU >= CK_V850E1)  // V850ES has same ISA as V850E1
        .Case("v850e2", CPU >= CK_V850E2)
        .Case("v850e2m", CPU >= CK_V850E2M)
        .Case("v850e3", CPU >= CK_V850E3)
        .Default(false);
  }

  ArrayRef<const char *> getGCCRegNames() const override;

  ArrayRef<TargetInfo::GCCRegAlias> getGCCRegAliases() const override {
    // Map special register names to their r-names
    static const TargetInfo::GCCRegAlias GCCRegAliases[] = {
        {{"sp"}, "r3"},
        {{"gp"}, "r4"},
        {{"tp"}, "r5"},
        {{"ep"}, "r30"},
        {{"lp"}, "r31"},
    };
    return llvm::ArrayRef(GCCRegAliases);
  }

  bool validateAsmConstraint(const char *&Name,
                             TargetInfo::ConstraintInfo &info) const override {
    switch (*Name) {
    default:
      return false;
    case 'r': // General purpose register
      info.setAllowsRegister();
      return true;
    }
  }

  std::string_view getClobbers() const override { return ""; }

  BuiltinVaListKind getBuiltinVaListKind() const override {
    return TargetInfo::CharPtrBuiltinVaList;
  }
};

} // namespace targets
} // namespace clang

#endif // LLVM_CLANG_LIB_BASIC_TARGETS_V850_H
