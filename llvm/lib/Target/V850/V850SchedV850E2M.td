//===-- V850SchedV850E2M.td - V850E2M Scheduling Definitions --*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file describes the V850E2M scheduling model with FPU support.
//
// V850E2M includes an FPU with the following characteristics:
// - Single and double precision IEEE 754 floating point
// - FPU operations run in parallel with integer operations
// - Non-pipelined divide and square root units
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// V850E2M Scheduling Model
//===----------------------------------------------------------------------===//

def V850E2MModel : SchedMachineModel {
  let MicroOpBufferSize = 0;    // V850E2M is in-order
  let IssueWidth = 1;           // Single-issue
  let LoadLatency = 2;          // Default load latency
  let MispredictPenalty = 3;    // Branch misprediction penalty
  let CompleteModel = false;    // Incomplete model
}

//===----------------------------------------------------------------------===//
// Define processor resources for V850E2M
//===----------------------------------------------------------------------===//

let SchedModel = V850E2MModel in {
  let BufferSize = 0 in {
    def V850E2MUnitALU      : ProcResource<1>;  // Integer ALU
    def V850E2MUnitMem      : ProcResource<1>;  // Load/Store unit
    def V850E2MUnitBranch   : ProcResource<1>;  // Branch unit
    def V850E2MUnitFPALU    : ProcResource<1>;  // FP ALU (add, sub, mul, cmp, cvt)
  }

  let BufferSize = 1 in {
    def V850E2MUnitMul      : ProcResource<1>;  // Integer multiply
    def V850E2MUnitDiv      : ProcResource<1>;  // Integer divide
    def V850E2MUnitFPDiv    : ProcResource<1>;  // FP divide/sqrt (not pipelined)
  }
}

//===----------------------------------------------------------------------===//
// V850E2M Integer Instruction Latencies
//===----------------------------------------------------------------------===//

let SchedModel = V850E2MModel in {

// Integer ALU - 1 cycle latency
def : WriteRes<WriteIALU, [V850E2MUnitALU]>;
def : WriteRes<WriteIALUimm, [V850E2MUnitALU]>;
def : WriteRes<WriteShift, [V850E2MUnitALU]>;
def : WriteRes<WriteShiftReg, [V850E2MUnitALU]>;
def : WriteRes<WriteMOV, [V850E2MUnitALU]>;
def : WriteRes<WriteCMP, [V850E2MUnitALU]>;
def : WriteRes<WriteExt, [V850E2MUnitALU]>;
def : WriteRes<WriteBSW, [V850E2MUnitALU]>;
def : WriteRes<WriteSat, [V850E2MUnitALU]>;
def : WriteRes<WriteBit, [V850E2MUnitALU]>;
def : WriteRes<WriteSCH, [V850E2MUnitALU]>;
def : WriteRes<WriteCMOV, [V850E2MUnitALU]>;

// Integer multiply - 2 cycles
def : WriteRes<WriteIMul, [V850E2MUnitMul]> { let Latency = 2; }

// Integer divide - 36 cycles (worst case for DIV/DIVU)
def : WriteRes<WriteIDiv, [V850E2MUnitDiv]> {
  let Latency = 36;
  let ReleaseAtCycles = [36];
}

// Quick divide (DIVQ/DIVQU) - ~20 cycles average (N+5 cycles)
def : WriteRes<WriteIDivQ, [V850E2MUnitDiv]> {
  let Latency = 20;
  let ReleaseAtCycles = [20];
}

// MAC - 3 cycles
def : WriteRes<WriteIMAC, [V850E2MUnitMul]> { let Latency = 3; }

// Memory operations
def : WriteRes<WriteLDB, [V850E2MUnitMem]> { let Latency = 3; }
def : WriteRes<WriteLDH, [V850E2MUnitMem]> { let Latency = 3; }
def : WriteRes<WriteLDW, [V850E2MUnitMem]> { let Latency = 2; }
def : WriteRes<WriteSTB, [V850E2MUnitMem]>;
def : WriteRes<WriteSTH, [V850E2MUnitMem]>;
def : WriteRes<WriteSTW, [V850E2MUnitMem]>;

// Branch operations
def : WriteRes<WriteJmp, [V850E2MUnitBranch]>;
def : WriteRes<WriteJal, [V850E2MUnitBranch]>;
def : WriteRes<WriteBranch, [V850E2MUnitBranch]>;

// Special instructions
def : WriteRes<WriteNop, []>;
def : WriteRes<WriteSys, [V850E2MUnitALU]>;
def : WriteRes<WritePREPARE, [V850E2MUnitMem]> { let Latency = 4; }
def : WriteRes<WriteDISPOSE, [V850E2MUnitMem]> { let Latency = 4; }
def : WriteRes<WriteCALLT, [V850E2MUnitBranch]> { let Latency = 2; }

//===----------------------------------------------------------------------===//
// V850E2M FPU Instruction Latencies
//
// Latency values are based on V850E2M User's Manual:
// - ADDF.S/SUBF.S: 4 cycles
// - ADDF.D/SUBF.D: 4 cycles
// - MULF.S: 4 cycles
// - MULF.D: 5 cycles
// - DIVF.S: ~35 cycles
// - DIVF.D: ~64 cycles
// - SQRTF.S: ~30 cycles
// - SQRTF.D: ~60 cycles
// - FMAF.S: 4 cycles (FMA)
// - FMAF.D: 5 cycles (FMA)
//===----------------------------------------------------------------------===//

// Single-precision FP add/sub - 4 cycles
def : WriteRes<WriteFAdd32, [V850E2MUnitFPALU]> { let Latency = 4; }

// Double-precision FP add/sub - 4 cycles
def : WriteRes<WriteFAdd64, [V850E2MUnitFPALU]> { let Latency = 4; }

// Single-precision FP multiply - 4 cycles
def : WriteRes<WriteFMul32, [V850E2MUnitFPALU]> { let Latency = 4; }

// Double-precision FP multiply - 5 cycles
def : WriteRes<WriteFMul64, [V850E2MUnitFPALU]> { let Latency = 5; }

// Single-precision FP divide - ~35 cycles (not pipelined)
def : WriteRes<WriteFDiv32, [V850E2MUnitFPDiv]> {
  let Latency = 35;
  let ReleaseAtCycles = [35];
}

// Double-precision FP divide - ~64 cycles (not pipelined)
def : WriteRes<WriteFDiv64, [V850E2MUnitFPDiv]> {
  let Latency = 64;
  let ReleaseAtCycles = [64];
}

// Single-precision FP sqrt - ~30 cycles (not pipelined)
def : WriteRes<WriteFSqrt32, [V850E2MUnitFPDiv]> {
  let Latency = 30;
  let ReleaseAtCycles = [30];
}

// Double-precision FP sqrt - ~60 cycles (not pipelined)
def : WriteRes<WriteFSqrt64, [V850E2MUnitFPDiv]> {
  let Latency = 60;
  let ReleaseAtCycles = [60];
}

// Single-precision FMA - 4 cycles
def : WriteRes<WriteFMA32, [V850E2MUnitFPALU]> { let Latency = 4; }

// Double-precision FMA - 5 cycles
def : WriteRes<WriteFMA64, [V850E2MUnitFPALU]> { let Latency = 5; }

// FP compare - 2 cycles
def : WriteRes<WriteFCmp, [V850E2MUnitFPALU]> { let Latency = 2; }

// FP conversion - 4 cycles
def : WriteRes<WriteFCvt, [V850E2MUnitFPALU]> { let Latency = 4; }

// FP move (ABSF, NEGF, etc.) - 1 cycle
def : WriteRes<WriteFMov, [V850E2MUnitFPALU]>;

// FP min/max - 2 cycles
def : WriteRes<WriteFMinMax, [V850E2MUnitFPALU]> { let Latency = 2; }

// FP load - same latency as integer loads
def : WriteRes<WriteFLD32, [V850E2MUnitMem]> { let Latency = 2; }
def : WriteRes<WriteFLD64, [V850E2MUnitMem]> { let Latency = 3; }

// FP store
def : WriteRes<WriteFST32, [V850E2MUnitMem]>;
def : WriteRes<WriteFST64, [V850E2MUnitMem]>;

//===----------------------------------------------------------------------===//
// Read Advances
//===----------------------------------------------------------------------===//

// Integer read advances (no forwarding penalty)
def : ReadAdvance<ReadIALU, 0>;
def : ReadAdvance<ReadIMul, 0>;
def : ReadAdvance<ReadIDiv, 0>;
def : ReadAdvance<ReadIMAC, 0>;
def : ReadAdvance<ReadMemBase, 0>;
def : ReadAdvance<ReadStoreData, 0>;
def : ReadAdvance<ReadJmp, 0>;
def : ReadAdvance<ReadBranch, 0>;
def : ReadAdvance<ReadCMOV, 0>;

// FPU read advances
def : ReadAdvance<ReadFAdd, 0>;
def : ReadAdvance<ReadFMul, 0>;
def : ReadAdvance<ReadFDiv, 0>;
def : ReadAdvance<ReadFMA, 0>;
def : ReadAdvance<ReadFMemBase, 0>;
def : ReadAdvance<ReadFStoreData, 0>;

// COPY instruction
def : InstRW<[WriteIALU], (instrs COPY)>;

} // SchedModel = V850E2MModel
