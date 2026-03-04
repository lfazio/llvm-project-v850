//===-- V850.h - Top-level interface for V850 representation ---*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the entry points for global functions defined in the LLVM
// V850 back-end.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V850_V850_H
#define LLVM_LIB_TARGET_V850_V850_H

#include "MCTargetDesc/V850MCTargetDesc.h"
#include "llvm/Target/TargetMachine.h"

namespace llvm {

class FunctionPass;
class V850TargetMachine;
class PassRegistry;

// createV850ISelDag - This pass converts a legalized DAG into a
// V850-specific DAG, ready for instruction scheduling.
FunctionPass *createV850ISelDag(V850TargetMachine &TM,
                                CodeGenOptLevel OptLevel);

// createV850LoadStoreOptimizerPass - This pass optimizes load/store
// operations, promoting 32-bit LD.W/ST.W to 16-bit SLD.W/SST.W when possible.
FunctionPass *createV850LoadStoreOptimizerPass();

// createV850PeepholeOptimizerPass - This pass performs peephole optimizations
// on V850 machine code, such as folding MOV+ADD to MOV immediate.
FunctionPass *createV850PeepholeOptimizerPass();

// createV850HardwareLoopPass - This pass converts ADD -1 + CMP 0 + BNZ
// patterns into the RH850G3M+ LOOP instruction.
FunctionPass *createV850HardwareLoopPass();

void initializeV850DAGToDAGISelLegacyPass(PassRegistry &);
void initializeV850LoadStoreOptimizerPass(PassRegistry &);
void initializeV850PeepholeOptimizerPass(PassRegistry &);
void initializeV850HardwareLoopPassPass(PassRegistry &);
void initializeV850AsmPrinterPass(PassRegistry &);

} // namespace llvm

#endif // LLVM_LIB_TARGET_V850_V850_H
