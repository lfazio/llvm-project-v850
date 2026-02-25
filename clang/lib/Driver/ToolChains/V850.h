//===--- V850.h - V850-specific Tool Helpers --------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_CLANG_LIB_DRIVER_TOOLCHAINS_V850_H
#define LLVM_CLANG_LIB_DRIVER_TOOLCHAINS_V850_H

#include "Gnu.h"
#include "clang/Driver/Driver.h"
#include "clang/Driver/InputInfo.h"
#include "clang/Driver/Tool.h"
#include "clang/Driver/ToolChain.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Option/Option.h"

namespace clang {
namespace driver {
namespace toolchains {

class LLVM_LIBRARY_VISIBILITY V850ToolChain : public Generic_ELF {
public:
  V850ToolChain(const Driver &D, const llvm::Triple &Triple,
                const llvm::opt::ArgList &Args);

  void
  AddClangSystemIncludeArgs(const llvm::opt::ArgList &DriverArgs,
                            llvm::opt::ArgStringList &CC1Args) const override;
  void addClangTargetOptions(const llvm::opt::ArgList &DriverArgs,
                             llvm::opt::ArgStringList &CC1Args,
                             Action::OffloadKind) const override;

  bool isPICDefault() const override { return false; }
  bool isPIEDefault(const llvm::opt::ArgList &Args) const override {
    return false;
  }
  bool isPICDefaultForced() const override { return true; }

  UnwindLibType
  GetUnwindLibType(const llvm::opt::ArgList &Args) const override {
    return UNW_None;
  }

protected:
  Tool *buildLinker() const override;

private:
  std::string computeSysRoot() const override;
};

} // end namespace toolchains

namespace tools {
namespace v850 {

class LLVM_LIBRARY_VISIBILITY Linker final : public Tool {
public:
  Linker(const ToolChain &TC) : Tool("V850::Linker", "v850-elf-ld", TC) {}
  bool hasIntegratedCPP() const override { return false; }
  bool isLinkJob() const override { return true; }
  void ConstructJob(Compilation &C, const JobAction &JA,
                    const InputInfo &Output, const InputInfoList &Inputs,
                    const llvm::opt::ArgList &TCArgs,
                    const char *LinkingOutput) const override;
};

void getV850TargetFeatures(const Driver &D, const llvm::opt::ArgList &Args,
                           std::vector<llvm::StringRef> &Features);

} // end namespace v850
} // end namespace tools
} // end namespace driver
} // end namespace clang

#endif // LLVM_CLANG_LIB_DRIVER_TOOLCHAINS_V850_H
