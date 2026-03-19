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
  using TTI = TargetTransformInfo;
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

  // Loop unrolling preferences
  void getUnrollingPreferences(Loop *L, ScalarEvolution &SE,
                               TTI::UnrollingPreferences &UP,
                               OptimizationRemarkEmitter *ORE) const override;

  // Vector register width for FXU (128-bit SIMD on RH850G4MH)
  TypeSize
  getRegisterBitWidth(TargetTransformInfo::RegisterKind K) const override;

  // Number of registers available for vectorization
  unsigned getNumberOfRegisters(unsigned ClassID) const override;

  // FXU vector loads/stores require 16-byte alignment
  bool allowsMisalignedMemoryAccesses(LLVMContext &Context, unsigned BitWidth,
                                      unsigned AddressSpace, Align Alignment,
                                      unsigned *Fast) const override;

  bool isLegalToVectorizeLoadChain(unsigned ChainSizeInBytes, Align Alignment,
                                   unsigned AddrSpace) const override;

  bool isLegalToVectorizeStoreChain(unsigned ChainSizeInBytes, Align Alignment,
                                    unsigned AddrSpace) const override;

  // FXU vector loads/stores require 16-byte alignment. When the vectorizer
  // queries with alignment < 16 (from the original scalar load), return a
  // high cost to prevent vectorization of unaligned data.
  InstructionCost getMemoryOpCost(
      unsigned Opcode, Type *Src, Align Alignment, unsigned AddressSpace,
      TTI::TargetCostKind CostKind,
      TTI::OperandValueInfo OpInfo = {TTI::OK_AnyValue, TTI::OP_None},
      const Instruction *I = nullptr) const override;

  // Vector insert/extract go through the stack on V850 (no direct GPR<->VGPR
  // move). This accurately reflects the high cost so the vectorizer avoids
  // scalarization patterns.
  InstructionCost getVectorInstrCost(unsigned Opcode, Type *Val,
                                     TTI::TargetCostKind CostKind,
                                     unsigned Index, const Value *Op0,
                                     const Value *Op1) const override;
  InstructionCost getVectorInstrCost(const Instruction &I, Type *Val,
                                     TTI::TargetCostKind CostKind,
                                     unsigned Index) const override;
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_V850_V850TARGETTRANSFORMINFO_H
