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
using namespace clang;
using namespace llvm::opt;

/// V850 Toolchain
V850ToolChain::V850ToolChain(const Driver &D, const llvm::Triple &Triple,
                             const ArgList &Args)
    : Generic_ELF(D, Triple, Args) {

  GCCInstallation.init(Triple, Args);
  if (GCCInstallation.isValid()) {
    SmallString<128> GCCBinPath;
    llvm::sys::path::append(GCCBinPath,
                            GCCInstallation.getParentLibPath(), "..", "bin");
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

  C.addCommand(std::make_unique<Command>(JA, *this,
                                         ResponseFileSupport::AtFileCurCP(),
                                         Args.MakeArgString(Linker), CmdArgs,
                                         Inputs, Output));
}
