//===--- V850.cpp - V850 Helpers for Tools ----------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "V850.h"
#include "Gnu.h"
#include "clang/Driver/CommonArgs.h"
#include "clang/Driver/Compilation.h"
#include "clang/Driver/InputInfo.h"
#include "clang/Driver/Options.h"
#include "llvm/Option/ArgList.h"
#include "llvm/Support/Path.h"

using namespace clang::driver;
using namespace clang::driver::toolchains;
using namespace clang::driver::tools;
using namespace llvm::opt;
using namespace clang;
using namespace llvm::opt;

/// Translate -mcpu=<cpu> into the corresponding set of target features.
/// V850E2M and later include the hardware FPU.
void v850::getV850TargetFeatures(const Driver &D, const ArgList &Args,
                                 std::vector<StringRef> &Features) {
  // Derive FPU capability from the CPU name.  CPUs that include V850E2M
  // or later implicitly have the hardware FPU.
  bool CPUHasFPU = false;
  if (const Arg *A = Args.getLastArg(options::OPT_mcpu_EQ)) {
    StringRef CPU = A->getValue();
    CPUHasFPU = llvm::StringSwitch<bool>(CPU)
                    .Cases("v850e2m", "v850e2v3", "v850e3", "v850e3v5", true)
                    .Cases("g3m", "g3mh", true)
                    .Cases("g4mh", "g4mh2", true)
                    .Default(false);
  }

  // -mhard-float / -msoft-float / -mno-soft-float / -msingle-float
  // override the CPU default.  Last flag wins.
  if (const Arg *A = Args.getLastArg(
          options::OPT_msoft_float, options::OPT_mno_soft_float,
          options::OPT_mhard_float, options::OPT_msingle_float)) {
    if (A->getOption().matches(options::OPT_msoft_float))
      CPUHasFPU = false;
    else
      CPUHasFPU = true; // -mhard-float, -mno-soft-float, -msingle-float
  }

  if (CPUHasFPU)
    Features.push_back("+v850fpu");
  else
    Features.push_back("-v850fpu");

  // -msoft-float also sets the soft-float ABI feature (use integer
  // registers for floating-point arguments).
  if (const Arg *A = Args.getLastArg(
          options::OPT_msoft_float, options::OPT_mno_soft_float,
          options::OPT_mhard_float, options::OPT_msingle_float)) {
    if (A->getOption().matches(options::OPT_msoft_float))
      Features.push_back("+soft-float");
  }

  // -msingle-float restricts to single-precision FPU only (no double).
  if (const Arg *A = Args.getLastArg(
          options::OPT_msoft_float, options::OPT_mno_soft_float,
          options::OPT_mhard_float, options::OPT_msingle_float)) {
    if (A->getOption().matches(options::OPT_msingle_float))
      Features.push_back("+single-float-only");
  }

  // Derive FXU (128-bit SIMD vector unit) capability from CPU.
  // FXU is available on RH850G4MH and G4MH2.
  bool CPUHasFXU = false;
  if (const Arg *A = Args.getLastArg(options::OPT_mcpu_EQ)) {
    StringRef CPU = A->getValue();
    CPUHasFXU = llvm::StringSwitch<bool>(CPU)
                    .Cases("g4mh", "g4mh2", true)
                    .Default(false);
  }

  // Explicit -mfxu / -mno-fxu override the CPU default.
  if (const Arg *A = Args.getLastArg(options::OPT_mfxu, options::OPT_mno_fxu)) {
    CPUHasFXU = A->getOption().matches(options::OPT_mfxu);
  }

  if (CPUHasFXU)
    Features.push_back("+v850fxu");
  else
    Features.push_back("-v850fxu");

  // Derive virtualization capability from CPU.
  // Virtualization is available on RH850G4MH2.
  bool CPUHasVirt = false;
  if (const Arg *A = Args.getLastArg(options::OPT_mcpu_EQ)) {
    StringRef CPU = A->getValue();
    CPUHasVirt =
        llvm::StringSwitch<bool>(CPU).Case("g4mh2", true).Default(false);
  }

  // Explicit -mvirt / -mno-virt override the CPU default.
  if (const Arg *A =
          Args.getLastArg(options::OPT_mvirt, options::OPT_mno_virt)) {
    CPUHasVirt = A->getOption().matches(options::OPT_mvirt);
  }

  if (CPUHasVirt)
    Features.push_back("+rh850g4mh2");
  else
    Features.push_back("-rh850g4mh2");
}

/// V850 Toolchain
V850ToolChain::V850ToolChain(const Driver &D, const llvm::Triple &Triple,
                             const ArgList &Args)
    : Generic_ELF(D, Triple, Args) {

  GCCInstallation.init(Triple, Args);
  if (GCCInstallation.isValid()) {
    SmallString<128> GCCBinPath;
    llvm::sys::path::append(GCCBinPath, GCCInstallation.getParentLibPath(),
                            "..", "bin");
    addPathIfExists(D, GCCBinPath, getProgramPaths());

    SmallString<128> GCCRtPath;
    llvm::sys::path::append(GCCRtPath, GCCInstallation.getInstallPath());
    addPathIfExists(D, GCCRtPath, getFilePaths());
  }

  SmallString<128> SysRootDir(computeSysRoot());
  llvm::sys::path::append(SysRootDir, "v850-elf", "lib");
  addPathIfExists(D, SysRootDir, getFilePaths());
}

std::string V850ToolChain::computeSysRoot() const {
  if (!getDriver().SysRoot.empty())
    return getDriver().SysRoot;

  SmallString<128> Dir;
  if (GCCInstallation.isValid())
    llvm::sys::path::append(Dir, GCCInstallation.getParentLibPath(), "..");
  else
    llvm::sys::path::append(Dir, getDriver().Dir, "..");

  return std::string(Dir);
}

void V850ToolChain::AddClangSystemIncludeArgs(const ArgList &DriverArgs,
                                              ArgStringList &CC1Args) const {
  if (DriverArgs.hasArg(options::OPT_nostdinc) ||
      DriverArgs.hasArg(options::OPT_nostdlibinc))
    return;

  SmallString<128> Dir(computeSysRoot());
  llvm::sys::path::append(Dir, "v850-elf", "include");
  addSystemInclude(DriverArgs, CC1Args, Dir.str());
}

void V850ToolChain::addClangTargetOptions(const ArgList &DriverArgs,
                                          ArgStringList &CC1Args,
                                          Action::OffloadKind) const {
  CC1Args.push_back("-nostdsysteminc");
}

Tool *V850ToolChain::buildLinker() const {
  return new tools::v850::Linker(*this);
}

void v850::Linker::ConstructJob(Compilation &C, const JobAction &JA,
                                const InputInfo &Output,
                                const InputInfoList &Inputs,
                                const ArgList &Args,
                                const char *LinkingOutput) const {
  const ToolChain &ToolChain = getToolChain();
  const Driver &D = ToolChain.getDriver();
  std::string Linker = ToolChain.GetProgramPath(getShortName());
  ArgStringList CmdArgs;

  if (!D.SysRoot.empty())
    CmdArgs.push_back(Args.MakeArgString("--sysroot=" + D.SysRoot));

  // Add library search paths
  ToolChain.AddFilePathLibArgs(Args, CmdArgs);
  Args.addAllArgs(CmdArgs, {options::OPT_L, options::OPT_T_Group,
                            options::OPT_s, options::OPT_t});

  // Specify output file
  CmdArgs.push_back("-o");
  CmdArgs.push_back(Output.getFilename());

  // Add input files
  for (const auto &II : Inputs) {
    if (II.isFilename()) {
      CmdArgs.push_back(II.getFilename());
    } else {
      const Arg &A = II.getInputArg();
      A.claim();
      A.render(Args, CmdArgs);
    }
  }

  // Add default libraries unless -nostdlib or -nodefaultlibs
  if (!Args.hasArg(options::OPT_nostdlib, options::OPT_nodefaultlibs)) {
    CmdArgs.push_back("--start-group");
    CmdArgs.push_back("-lc");
    CmdArgs.push_back("-lgcc");
    CmdArgs.push_back("--end-group");
  }

  C.addCommand(std::make_unique<Command>(
      JA, *this, ResponseFileSupport::AtFileCurCP(), Args.MakeArgString(Linker),
      CmdArgs, Inputs, Output));
}
