//===-- V850TargetTransformInfo.h - V850 specific TTI ----------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
/// \file
/// This file provides a TargetTransformInfo implementation specific to the
/// V850 target machine.
///
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V850_V850TARGETTRANSFORMINFO_H
#define LLVM_LIB_TARGET_V850_V850TARGETTRANSFORMINFO_H

#include "V850TargetMachine.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/CodeGen/BasicTTIImpl.h"

namespace llvm {

class V850TTIImpl final : public BasicTTIImplBase<V850TTIImpl> {
  using BaseT = BasicTTIImplBase<V850TTIImpl>;
  friend BaseT;

  const V850Subtarget *ST;
  const V850TargetLowering *TLI;

  const V850Subtarget *getST() const { return ST; }
  const V850TargetLowering *getTLI() const { return TLI; }

public:
  explicit V850TTIImpl(const V850TargetMachine *TM, const Function &F)
      : BaseT(TM, F.getDataLayout()), ST(TM->getSubtargetImpl(F)),
        TLI(ST->getTargetLowering()) {}

  // Hardware loop support (RH850G3M+ LOOP instruction)
  bool isHardwareLoopProfitable(Loop *L, ScalarEvolution &SE,
                                AssumptionCache &AC, TargetLibraryInfo *LibInfo,
                                HardwareLoopInfo &HWLoopInfo) const override;
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_V850_V850TARGETTRANSFORMINFO_H
