//===-- V850TargetTransformInfo.cpp - V850 specific TTI -------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements a TargetTransformInfo analysis pass specific to the
// V850 target machine.
//
//===----------------------------------------------------------------------===//

#include "V850TargetTransformInfo.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/CodeGen/TargetLowering.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/Type.h"

using namespace llvm;

#define DEBUG_TYPE "v850tti"

bool V850TTIImpl::isHardwareLoopProfitable(Loop *L, ScalarEvolution &SE,
                                           AssumptionCache &AC,
                                           TargetLibraryInfo *LibInfo,
                                           HardwareLoopInfo &HWLoopInfo) const {
  // LOOP instruction is only available on RH850G3M+.
  if (!ST->hasRH850G3M())
    return false;

  // Don't convert if the loop already has hardware loop intrinsics.
  for (auto *BB : L->getBlocks())
    for (auto &I : *BB)
      if (auto *Call = dyn_cast<IntrinsicInst>(&I))
        if (Call->getIntrinsicID() == Intrinsic::start_loop_iterations ||
            Call->getIntrinsicID() == Intrinsic::loop_decrement_reg)
          return false;

  // V850 LOOP instruction uses a GPR as the counter register.
  // CounterInReg = true: the counter flows through phi nodes as a regular
  // GPR value. This uses start_loop_iterations (returns count) and
  // loop_decrement_reg (takes counter, returns decremented counter).
  LLVMContext &C = L->getHeader()->getContext();
  HWLoopInfo.CounterInReg = true;
  HWLoopInfo.CountType = Type::getInt32Ty(C);
  HWLoopInfo.LoopDecrement = ConstantInt::get(HWLoopInfo.CountType, 1);
  HWLoopInfo.IsNestingLegal = false;

  return true;
}
