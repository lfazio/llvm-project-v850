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

// V850E1/V850ES feature - adds extended instruction set:
// CALLT, DISPOSE, PREPARE, SXB, SXH, ZXB, ZXH, BSH, BSW, HSW, CMOV,
// 3-op DIV/MUL, SASF, LD.BU, LD.HU, SLD.BU, SLD.HU, DBTRAP/DBRET
//
// Note: V850ES and V850E1 share the same instruction set architecture (ISA).
// The difference is in available system registers:
// - V850ES: 6 base system registers (EIPC, EIPSW, FEPC, FEPSW, ECR, PSW)
// - V850E1: 6 base + 12 additional system registers (CTPC, CTPSW, DBPC, DBPSW,
//           CTBP, DIR, BPC, ASID, BPAV, BPAM, BPDV, BPDM)
//
// The compiler does not enforce system register restrictions at compile time.
// System register availability is a hardware/documentation concern.
def FeatureV850E1 : SubtargetFeature<"v850e1", "HasV850E1", "true",
                                      "Enable V850E1/ES instruction extensions",
                                      []>;

// V850E2 feature - adds ADF, SBF, 32-bit branches, MAC, MACU, search bit ops
def FeatureV850E2 : SubtargetFeature<"v850e2", "HasV850E2", "true",
                                      "Enable V850E2 extensions",
                                      [FeatureV850E1]>;

// V850E2M feature - adds FPU
def FeatureV850FPU : SubtargetFeature<"v850fpu", "HasV850FPU", "true",
                                      "Enable V850 FPU extensions",
                                      []>;

// V850E2M feature - adds FPU
def FeatureV850E2M : SubtargetFeature<"v850e2m", "HasV850E2M", "true",
                                       "Enable V850E2M extensions (includes FPU)",
                                       [FeatureV850E2, FeatureV850FPU]>;

// V850E3 feature - additional extensions
def FeatureV850E3 : SubtargetFeature<"v850e3", "HasV850E3", "true",
                                      "Enable V850E3 extensions",
                                      [FeatureV850E2M]>;

// RH850G3M feature - adds user/supervisor modes, atomics, cache control
// New instructions: LDL.W, STC.W, CLL, BINS, ROTL, LD.DW, ST.DW, LOOP,
// PUSHSP, POPSP, Bcond disp17, JARL [reg1] reg3, CACHE, PREF, SNOOZE, SYNCI
def FeatureRH850G3M : SubtargetFeature<"rh850g3m", "HasRH850G3M", "true",
                                        "Enable RH850G3M extensions",
                                        [FeatureV850E2M]>;

// RH850G3MH feature - G3M with performance enhancements
// Simplified FPU exceptions (FPINT replaces FPP/FPI), FPIPR register removed
def FeatureRH850G3MH : SubtargetFeature<"rh850g3mh", "HasRH850G3MH", "true",
                                         "Enable RH850G3MH extensions",
                                         [FeatureRH850G3M]>;

//===----------------------------------------------------------------------===//
// Register File, Calling Conv, Instruction Descriptions
//===----------------------------------------------------------------------===//

include "V850RegisterInfo.td"
include "V850CallingConv.td"
include "V850InstrInfo.td"
include "V850Schedule.td"
include "V850SchedV850E1.td"
include "V850SchedV850E2M.td"
include "V850SchedRH850G3M.td"

def V850InstrInfo : InstrInfo;

//===----------------------------------------------------------------------===//
// V850 processors supported
//===----------------------------------------------------------------------===//

// Base V850 processors use V850Model (no FPU)
def : ProcessorModel<"generic", V850Model, []>;
def : ProcessorModel<"v850", V850Model, []>;

// V850ES and V850E1 share the same instruction set but differ in system registers
// V850ES: Base 6 system registers only
// V850E1: Base 6 + 12 additional debug/CALLT system registers
// Both use FeatureV850E1 for instruction set (compiler doesn't enforce register restrictions)
// Both use V850E1Model for scheduling (different MUL/branch timings from base V850)
def : ProcessorModel<"v850es", V850E1Model, [FeatureV850E1]>;
def : ProcessorModel<"v850e1", V850E1Model, [FeatureV850E1]>;

// V850E2 uses same pipeline as V850E2M (7-stage dual-issue) but without FPU
def : ProcessorModel<"v850e2", V850E2MModel, [FeatureV850E2]>;

// V850E2M+ processors use V850E2MModel (includes FPU)
def : ProcessorModel<"v850e2m", V850E2MModel, [FeatureV850E2M]>;
def : ProcessorModel<"v850e2v3", V850E2MModel, [FeatureV850E2M]>;
def : ProcessorModel<"v850e3", V850E2MModel, [FeatureV850E3]>;
def : ProcessorModel<"v850e3v5", V850E2MModel, [FeatureV850E3]>;

// RH850 processors (use RH850G3MModel - improved timings over V850E2M)
def : ProcessorModel<"g3m", RH850G3MModel, [FeatureRH850G3M]>;
def : ProcessorModel<"g3mh", RH850G3MModel, [FeatureRH850G3MH]>;

//===----------------------------------------------------------------------===//
// V850 assembly writer
//===----------------------------------------------------------------------===//

def V850InstPrinter : AsmWriter {
  string AsmWriterClassName = "InstPrinter";
  bit isMCAsmWriter = 1;
  int PassSubtarget = 1;
}

//===----------------------------------------------------------------------===//
// V850 assembly parser
//===----------------------------------------------------------------------===//

def V850AsmParser : AsmParser {
  let ShouldEmitMatchRegisterAltName = 1;
  let AllowDuplicateRegisterNames = 1;
}

//===----------------------------------------------------------------------===//
// Declare the target which we are implementing
//===----------------------------------------------------------------------===//

def V850 : Target {
  let InstructionSet = V850InstrInfo;
  let AssemblyWriters = [V850InstPrinter];
  let AssemblyParsers = [V850AsmParser];
}
