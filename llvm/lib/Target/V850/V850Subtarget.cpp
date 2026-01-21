//===-- V850Subtarget.cpp - V850 Subtarget Information --------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements the V850 specific subclass of TargetSubtargetInfo.
//
//===----------------------------------------------------------------------===//

#include "V850Subtarget.h"
#include "V850.h"
#include "llvm/MC/TargetRegistry.h"

using namespace llvm;

#define DEBUG_TYPE "v850-subtarget"

#define GET_SUBTARGETINFO_TARGET_DESC
#define GET_SUBTARGETINFO_CTOR
#include "V850GenSubtargetInfo.inc"

void V850Subtarget::anchor() {}

V850Subtarget &V850Subtarget::initializeSubtargetDependencies(StringRef CPU,
                                                               StringRef FS) {
  StringRef CPUName = CPU;
  if (CPUName.empty())
    CPUName = "v850";

  ParseSubtargetFeatures(CPUName, /*TuneCPU*/ CPUName, FS);

  return *this;
}

V850Subtarget::V850Subtarget(const Triple &TT, const std::string &CPU,
                             const std::string &FS, const TargetMachine &TM)
    : V850GenSubtargetInfo(TT, CPU, /*TuneCPU*/ CPU, FS),
      InstrInfo(initializeSubtargetDependencies(CPU, FS)),
      TLInfo(TM, *this),
      FrameLowering(*this) {}

void V850Subtarget::getCriticalPathRCs(RegClassVector &CriticalPathRCs) const {
  // For post-RA scheduling anti-dependency breaking, prioritize GPR registers
  // on the critical path. This helps the scheduler make better decisions about
  // which anti-dependencies to break to reduce stalls.
  CriticalPathRCs.clear();
  CriticalPathRCs.push_back(&V850::GPRRegClass);
}
