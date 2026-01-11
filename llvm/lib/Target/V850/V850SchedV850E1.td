//===-- V850SchedV850E1.td - V850E1/ES Scheduling Definitions --*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file describes the V850E1/V850ES scheduling model.
//
// V850ES and V850E1 share the same 5-stage pipeline (IF-ID-EX-MEM-WB)
// and instruction set, but differ in available system registers.
//
// Key differences from base V850:
// - MUL/MULU instructions: 1-4-5 (repeat 4, latency 5) vs 1-1-2 for MULH
// - Branches: 2-2-2 (taken) vs 3-3-3
// - SLD.* short loads: 1-1-1 vs 1-1-2
// - PREPARE/DISPOSE/CALLT available
// - Extended instructions: BSH, BSW, HSW, SXB, SXH, ZXB, ZXH, CMOV, etc.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// V850E1 Scheduling Model
//===----------------------------------------------------------------------===//

def V850E1Model : SchedMachineModel {
  let MicroOpBufferSize = 0;    // V850E1/ES is in-order
  let IssueWidth = 1;           // Single-issue
  let LoadLatency = 2;          // Default load latency (LD.* is 1-1-2)
  let MispredictPenalty = 2;    // Branch taken penalty (2 cycles)
  let CompleteModel = false;    // Incomplete model
}

//===----------------------------------------------------------------------===//
// Define processor resources for V850E1
//===----------------------------------------------------------------------===//

let SchedModel = V850E1Model in {
  let BufferSize = 0 in {
    def V850E1UnitALU      : ProcResource<1>;  // Integer ALU
    def V850E1UnitMem      : ProcResource<1>;  // Load/Store unit
    def V850E1UnitBranch   : ProcResource<1>;  // Branch unit
  }

  let BufferSize = 1 in {
    def V850E1UnitMul      : ProcResource<1>;  // Integer multiply
    def V850E1UnitDiv      : ProcResource<1>;  // Integer divide
  }
}

//===----------------------------------------------------------------------===//
// V850E1 Instruction Latencies
//===----------------------------------------------------------------------===//

let SchedModel = V850E1Model in {

// Integer ALU - 1 cycle latency (1-1-1)
def : WriteRes<WriteIALU, [V850E1UnitALU]>;
def : WriteRes<WriteIALUimm, [V850E1UnitALU]>;
def : WriteRes<WriteShift, [V850E1UnitALU]>;
def : WriteRes<WriteShiftReg, [V850E1UnitALU]>;
def : WriteRes<WriteMOV, [V850E1UnitALU]>;
def : WriteRes<WriteCMP, [V850E1UnitALU]>;
def : WriteRes<WriteExt, [V850E1UnitALU]>;     // SXB, SXH, ZXB, ZXH
def : WriteRes<WriteBSW, [V850E1UnitALU]>;     // BSH, BSW, HSW
def : WriteRes<WriteSat, [V850E1UnitALU]>;     // SATADD, SATSUB
def : WriteRes<WriteBit, [V850E1UnitALU]>;     // SET1, CLR1, NOT1, TST1
def : WriteRes<WriteSCH, [V850E1UnitALU]>;     // Not available on E1
def : WriteRes<WriteCMOV, [V850E1UnitALU]>;    // CMOV

// Integer multiply - MULH is 1-1-2, but MUL/MULU is 1-4-5
// Using conservative estimate for general WriteIMul
def : WriteRes<WriteIMul, [V850E1UnitMul]> {
  let Latency = 5;
  let ReleaseAtCycles = [4];  // Repeat rate of 4
}

// Integer divide - DIV/DIVU/DIVH is 35-35-35
def : WriteRes<WriteIDiv, [V850E1UnitDiv]> {
  let Latency = 35;
  let ReleaseAtCycles = [35];
}

// Quick divide (DIVQ/DIVQU) - not available on V850E1
let Unsupported = true in
def : WriteRes<WriteIDivQ, [V850E1UnitDiv]> {
  let Latency = 20;
  let ReleaseAtCycles = [20];
}

// MAC - not available on V850E1 (available starting V850E2)
let Unsupported = true in
def : WriteRes<WriteIMAC, [V850E1UnitMul]> { let Latency = 3; }

// Memory operations
// LD.* is 1-1-2, but SLD.* short loads are 1-1-1 (faster)
def : WriteRes<WriteLDB, [V850E1UnitMem]> { let Latency = 2; }
def : WriteRes<WriteLDH, [V850E1UnitMem]> { let Latency = 2; }
def : WriteRes<WriteLDW, [V850E1UnitMem]> { let Latency = 2; }
def : WriteRes<WriteSTB, [V850E1UnitMem]>;
def : WriteRes<WriteSTH, [V850E1UnitMem]>;
def : WriteRes<WriteSTW, [V850E1UnitMem]>;

// Branch operations - V850E1: JR/JARL are 2-2-2, JMP is 3-3-3
def : WriteRes<WriteJmp, [V850E1UnitBranch]> { let Latency = 3; }
def : WriteRes<WriteJal, [V850E1UnitBranch]> { let Latency = 2; }
def : WriteRes<WriteBranch, [V850E1UnitBranch]> { let Latency = 2; }

// Special instructions
def : WriteRes<WriteNop, []>;
def : WriteRes<WriteSys, [V850E1UnitALU]>;  // LDSR/STSR: 1-1-1

// PREPARE: n+1 to n+3 cycles depending on variant (n = registers in list)
// Using average estimate of 4 cycles
def : WriteRes<WritePREPARE, [V850E1UnitMem]> {
  let Latency = 4;
  let ReleaseAtCycles = [4];
}

// DISPOSE: n+1 to n+3 cycles depending on variant
def : WriteRes<WriteDISPOSE, [V850E1UnitMem]> {
  let Latency = 4;
  let ReleaseAtCycles = [4];
}

// CALLT: 4-4-4
def : WriteRes<WriteCALLT, [V850E1UnitBranch]> { let Latency = 4; }

// Read advances (no forwarding penalty)
def : ReadAdvance<ReadIALU, 0>;
def : ReadAdvance<ReadIMul, 0>;
def : ReadAdvance<ReadIDiv, 0>;
def : ReadAdvance<ReadIMAC, 0>;
def : ReadAdvance<ReadMemBase, 0>;
def : ReadAdvance<ReadStoreData, 0>;
def : ReadAdvance<ReadJmp, 0>;
def : ReadAdvance<ReadBranch, 0>;
def : ReadAdvance<ReadCMOV, 0>;

// FPU write resources - mark as unsupported for V850E1 (no FPU)
let Unsupported = true in {
  def : WriteRes<WriteFAdd32, []>;
  def : WriteRes<WriteFAdd64, []>;
  def : WriteRes<WriteFMul32, []>;
  def : WriteRes<WriteFMul64, []>;
  def : WriteRes<WriteFDiv32, []>;
  def : WriteRes<WriteFDiv64, []>;
  def : WriteRes<WriteFSqrt32, []>;
  def : WriteRes<WriteFSqrt64, []>;
  def : WriteRes<WriteFMA32, []>;
  def : WriteRes<WriteFMA64, []>;
  def : WriteRes<WriteFCmp, []>;
  def : WriteRes<WriteFCvt, []>;
  def : WriteRes<WriteFMov, []>;
  def : WriteRes<WriteFMinMax, []>;
  def : WriteRes<WriteFLD32, []>;
  def : WriteRes<WriteFLD64, []>;
  def : WriteRes<WriteFST32, []>;
  def : WriteRes<WriteFST64, []>;
}

// FPU read advances - mark as unsupported for V850E1
let Unsupported = true in {
  def : ReadAdvance<ReadFAdd, 0>;
  def : ReadAdvance<ReadFMul, 0>;
  def : ReadAdvance<ReadFDiv, 0>;
  def : ReadAdvance<ReadFMA, 0>;
  def : ReadAdvance<ReadFMemBase, 0>;
  def : ReadAdvance<ReadFStoreData, 0>;
}

// COPY instruction
def : InstRW<[WriteIALU], (instrs COPY)>;

} // SchedModel = V850E1Model
