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

  // Scan loop body: bail out on calls (prevents inlining).
  // Also bail on vectors unless FXU is available.
  InstructionCost Cost = 0;
  bool HasFPOps = false;
  for (auto *BB : L->getBlocks()) {
    for (auto &I : *BB) {
      if (I.getType()->isVectorTy() && !ST->hasV850FXU())
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
  UP.UnrollRemainder = false;

  // Limit unroll count to 4. V850 has 32 GPRs but 12 are callee-saved
  // (r20-r31), leaving ~19 volatile registers. An unroll-by-8 of a typical
  // 3-operand loop body (2 loads + op + store) exceeds this budget and
  // causes excessive spilling. Unroll-by-4 matches V850E2M dual-issue
  // pipeline depth and available register pressure.
  UP.Count = 4;
  UP.MaxCount = 4;

  // Force unrolling very small loops to eliminate branch overhead.
  if (Cost < 12)
    UP.Force = true;
}

TypeSize
V850TTIImpl::getRegisterBitWidth(TargetTransformInfo::RegisterKind K) const {
  switch (K) {
  case TargetTransformInfo::RGK_Scalar:
    return TypeSize::getFixed(32);
  case TargetTransformInfo::RGK_FixedWidthVector:
    // FXU provides 128-bit SIMD registers (wreg0-wreg31).
    if (ST->hasV850FXU())
      return TypeSize::getFixed(128);
    return TypeSize::getFixed(32);
  case TargetTransformInfo::RGK_ScalableVector:
    return TypeSize::getScalable(0);
  }
  llvm_unreachable("Unsupported register kind");
}

unsigned V850TTIImpl::getNumberOfRegisters(unsigned ClassID) const {
  if (ClassID == 1) {
    // Vector registers: 32 wreg registers on FXU.
    if (ST->hasV850FXU())
      return 32;
    return 0;
  }
  // Scalar: 32 GPRs.
  return 32;
}

bool V850TTIImpl::allowsMisalignedMemoryAccesses(LLVMContext &Context,
                                                 unsigned BitWidth,
                                                 unsigned AddressSpace,
                                                 Align Alignment,
                                                 unsigned *Fast) const {
  // FXU vector loads/stores (LDV.QW/STV.QW) require 16-byte alignment.
  // Misaligned access causes MAE (Misalignment Exception).
  if (BitWidth == 128 && ST->hasV850FXU()) {
    if (Alignment >= Align(16)) {
      if (Fast)
        *Fast = 1;
      return true;
    }
    return false;
  }

  // Scalar accesses: V850 handles misaligned access (with penalty).
  if (BitWidth <= 64) {
    if (Fast)
      *Fast = (Alignment >= Align(BitWidth / 8)) ? 1 : 0;
    return true;
  }

  return false;
}

bool V850TTIImpl::isLegalToVectorizeLoadChain(unsigned ChainSizeInBytes,
                                              Align Alignment,
                                              unsigned AddrSpace) const {
  // FXU requires 16-byte alignment for 128-bit vector loads.
  if (ChainSizeInBytes > 8 && ST->hasV850FXU())
    return Alignment >= Align(16);

  return true;
}

bool V850TTIImpl::isLegalToVectorizeStoreChain(unsigned ChainSizeInBytes,
                                               Align Alignment,
                                               unsigned AddrSpace) const {
  // FXU requires 16-byte alignment for 128-bit vector stores.
  if (ChainSizeInBytes > 8 && ST->hasV850FXU())
    return Alignment >= Align(16);

  return true;
}

InstructionCost V850TTIImpl::getMemoryOpCost(unsigned Opcode, Type *Src,
                                             Align Alignment,
                                             unsigned AddressSpace,
                                             TTI::TargetCostKind CostKind,
                                             TTI::OperandValueInfo OpInfo,
                                             const Instruction *I) const {
  // FXU vector loads/stores (LDV.QW/STV.QW) require 16-byte alignment.
  // The loop vectorizer queries this with the *original scalar* alignment
  // (e.g. align 4 for float*). If the user provides align 16 via
  // __builtin_assume_aligned or aligned allocations, we get align 16 here
  // and return the normal cost. Otherwise, return a prohibitive cost to
  // prevent the vectorizer from creating vector loads that will be
  // scalarized through the stack in the backend.
  if (ST->hasV850FXU() && Src->isVectorTy() && Alignment < Align(16))
    return 100;

  return BaseT::getMemoryOpCost(Opcode, Src, Alignment, AddressSpace, CostKind,
                                OpInfo, I);
}

InstructionCost V850TTIImpl::getVectorInstrCost(unsigned Opcode, Type *Val,
                                                TTI::TargetCostKind CostKind,
                                                unsigned Index,
                                                const Value *Op0,
                                                const Value *Op1) const {
  // V850 FXU has no direct GPR<->VGPR move instruction. INSERT_VECTOR_ELT
  // and EXTRACT_VECTOR_ELT must go through the stack (store + load), costing
  // ~3 cycles each. This high cost prevents the vectorizer from creating
  // scalarized vector code that is worse than pure scalar.
  if (ST->hasV850FXU() && Val->isVectorTy())
    return 10;

  return BaseT::getVectorInstrCost(Opcode, Val, CostKind, Index, Op0, Op1);
}

InstructionCost V850TTIImpl::getVectorInstrCost(const Instruction &I, Type *Val,
                                                TTI::TargetCostKind CostKind,
                                                unsigned Index) const {
  if (ST->hasV850FXU() && Val->isVectorTy())
    return 10;

  return BaseT::getVectorInstrCost(I, Val, CostKind, Index);
}
