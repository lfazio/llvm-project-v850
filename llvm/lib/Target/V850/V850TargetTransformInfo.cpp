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
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/CodeGen/TargetLowering.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/Type.h"
#include "llvm/Support/Debug.h"

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

void V850TTIImpl::getUnrollingPreferences(
    Loop *L, ScalarEvolution &SE, TTI::UnrollingPreferences &UP,
    OptimizationRemarkEmitter *ORE) const {

  // Enable upper-bound unrolling universally.
  UP.UpperBound = true;

  // Disable loop unrolling for -Os and -Oz. V850 is an embedded target
  // where code size is often critical.
  UP.OptSizeThreshold = 0;
  UP.PartialOptSizeThreshold = 0;
  if (L->getHeader()->getParent()->hasOptSize())
    return;

  SmallVector<BasicBlock *, 4> ExitingBlocks;
  L->getExitingBlocks(ExitingBlocks);
  LLVM_DEBUG(dbgs() << "V850 Unroll: Blocks=" << L->getNumBlocks()
                    << " ExitBlocks=" << ExitingBlocks.size() << "\n");

  // Only allow the latch plus at most one early exit.
  if (ExitingBlocks.size() > 2)
    return;

  // Limit loop body complexity: allow if-then-else diamonds (4 blocks max).
  if (L->getNumBlocks() > 4)
    return;

  // Don't unroll vectorized loops.
  if (getBooleanLoopAttribute(L, "llvm.loop.isvectorized"))
    return;

  // Scan loop body: bail out on calls (prevents inlining) and vectors.
  InstructionCost Cost = 0;
  bool HasFPOps = false;
  for (auto *BB : L->getBlocks()) {
    for (auto &I : *BB) {
      if (I.getType()->isVectorTy())
        return;

      if (isa<CallInst>(I) || isa<InvokeInst>(I)) {
        if (const Function *F = cast<CallBase>(I).getCalledFunction()) {
          if (!isLoweredToCall(F))
            continue;
        }
        return;
      }

      // Track FP operations for V850E2M+ dual-issue benefit.
      if (I.getType()->isFloatingPointTy())
        HasFPOps = true;

      SmallVector<const Value *> Operands(I.operand_values());
      Cost += getInstructionCost(&I, Operands,
                                 TargetTransformInfo::TCK_SizeAndLatency);
    }
  }

  LLVM_DEBUG(dbgs() << "V850 Unroll: Cost=" << Cost << " HasFP=" << HasFPOps
                    << "\n");

  UP.Partial = true;
  UP.Runtime = true;
  UP.UnrollRemainder = true;

  // Force unrolling very small loops to eliminate branch overhead.
  if (Cost < 12)
    UP.Force = true;
}
