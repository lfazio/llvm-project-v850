//===- V850.td - Describe the V850 Target Machine ----------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This is the top level entry point for the V850 target.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Target-independent interfaces which we are implementing
//===----------------------------------------------------------------------===//

include "llvm/Target/Target.td"

//===----------------------------------------------------------------------===//
// V850 subtarget features and instruction predicates
//===----------------------------------------------------------------------===//

// V850E1/V850ES feature - adds extended instruction set
def FeatureV850E1 : SubtargetFeature<"v850e1", "HasV850E1", "true",
                                      "Enable V850E1/ES instruction extensions",
                                      []>;

// V850E2 feature - adds ADF, SBF, 32-bit branches, MAC, MACU, search bit ops
def FeatureV850E2 : SubtargetFeature<"v850e2", "HasV850E2", "true",
                                      "Enable V850E2 extensions",
                                      [FeatureV850E1]>;

// V850 FPU feature
def FeatureV850FPU : SubtargetFeature<"v850fpu", "HasV850FPU", "true",
                                      "Enable V850 FPU extensions",
                                      []>;

// V850E2M feature - adds FPU
def FeatureV850E2M : SubtargetFeature<"v850e2m", "HasV850E2M", "true",
                                       "Enable V850E2M extensions (includes FPU)",
                                       [FeatureV850E2, FeatureV850FPU]>;

//===----------------------------------------------------------------------===//
// Register File Description
//===----------------------------------------------------------------------===//

include "V850RegisterInfo.td"

//===----------------------------------------------------------------------===//
// V850 Target
//===----------------------------------------------------------------------===//

def V850InstrInfo : InstrInfo;

def V850 : Target {
  let InstructionSet = V850InstrInfo;
}
