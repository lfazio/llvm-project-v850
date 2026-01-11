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
// V850E2/E2M features a 7-stage dual-issue superscalar pipeline:
//   IF (Instruction Fetch) -> DP (Pre-Decode) -> ID (Decode) ->
//   EX (Execute) -> AT (Address Translation) -> DF (Data Fetch) -> WB
//
// Dual-issue resources:
//   - Lpipe: Load/store, multiply, MAC operations
//   - Rpipe: ALU, shift, data manipulation, bit search
//   - Both pipes can execute many arithmetic/logical operations
//
// Parallel issue restrictions:
//   - Same-pipe instructions cannot dual-issue
//   - 6-byte instructions cannot dual-issue
//   - Some special instructions are single-issue only
//
// FPU characteristics:
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
  let IssueWidth = 2;           // Dual-issue superscalar (Lpipe + Rpipe)
  let LoadLatency = 3;          // Default load latency (1-1-3)
  let MispredictPenalty = 4;    // Branch taken penalty (4-4-4)
  let CompleteModel = false;    // Incomplete model
}

//===----------------------------------------------------------------------===//
// Define processor resources for V850E2M
//
// Dual-issue pipeline resources:
//   Lpipe: Load/store, multiply, MAC
//   Rpipe: ALU, shift, data manipulation, bit search
//   Both: Can execute many arithmetic/logical ops
//===----------------------------------------------------------------------===//

let SchedModel = V850E2MModel in {
  let BufferSize = 0 in {
    // Dual-issue pipe resources
    def V850E2MLpipe        : ProcResource<1>;  // L-pipe (load/store, mul, MAC)
    def V850E2MRpipe        : ProcResource<1>;  // R-pipe (ALU, shift, bit search)

    // Combined resource for instructions that can use either pipe
    def V850E2MAnyPipe      : ProcResource<2>;  // Either pipe (most ALU ops)

    def V850E2MUnitBranch   : ProcResource<1>;  // Branch unit
    def V850E2MUnitFPALU    : ProcResource<1>;  // FP ALU (add, sub, mul, cmp, cvt)
  }

  let BufferSize = 1 in {
    def V850E2MUnitDiv      : ProcResource<1>;  // Integer divide (blocking)
    def V850E2MUnitFPDiv    : ProcResource<1>;  // FP divide/sqrt (not pipelined)
  }

  // Create resource groups for dual-issue modeling
  // Instructions using Lpipe or Rpipe consume from the combined AnyPipe resource
  def V850E2MLpipeGroup : ProcResGroup<[V850E2MLpipe]>;
  def V850E2MRpipeGroup : ProcResGroup<[V850E2MRpipe]>;
}

//===----------------------------------------------------------------------===//
// V850E2M Integer Instruction Latencies
//
// Resources assignment:
//   - Rpipe: ALU, shift, data manipulation, bit search, conditional move
//   - Lpipe: load/store, multiply, MAC
//   - AnyPipe: most arithmetic/logical operations can use either pipe
//===----------------------------------------------------------------------===//

let SchedModel = V850E2MModel in {

// Integer ALU - 1 cycle latency (1-1-1)
// Most ALU ops can use either pipe
def : WriteRes<WriteIALU, [V850E2MAnyPipe]>;
def : WriteRes<WriteIALUimm, [V850E2MAnyPipe]>;
def : WriteRes<WriteMOV, [V850E2MAnyPipe]>;
def : WriteRes<WriteCMP, [V850E2MAnyPipe]>;
def : WriteRes<WriteSat, [V850E2MAnyPipe]>;    // SATADD/SATSUB

// Shift operations - Rpipe only (1-1-1)
def : WriteRes<WriteShift, [V850E2MRpipe]>;
def : WriteRes<WriteShiftReg, [V850E2MRpipe]>;

// Data manipulation - Rpipe only (1-1-1)
def : WriteRes<WriteExt, [V850E2MRpipe]>;      // SXB, SXH, ZXB, ZXH
def : WriteRes<WriteBSW, [V850E2MRpipe]>;      // BSH, BSW, HSH, HSW

// Bit search - Rpipe only (1-1-1)
def : WriteRes<WriteSCH, [V850E2MRpipe]>;      // SCH0L, SCH0R, SCH1L, SCH1R

// Conditional move - can use either pipe (1-1-1)
def : WriteRes<WriteCMOV, [V850E2MAnyPipe]>;   // CMOV, ADF, SBF

// Bit manipulation - uses Lpipe for memory access (4-4-4)
def : WriteRes<WriteBit, [V850E2MLpipe]> { let Latency = 4; }

// Integer multiply - Lpipe only (1-1-3)
def : WriteRes<WriteIMul, [V850E2MLpipe]> { let Latency = 3; }

// Integer divide - 36 cycles (worst case for DIV/DIVU)
def : WriteRes<WriteIDiv, [V850E2MUnitDiv]> {
  let Latency = 36;
  let ReleaseAtCycles = [36];
}

// Quick divide (DIVQ/DIVQU) - N+5 cycles (N = valid bits difference)
def : WriteRes<WriteIDivQ, [V850E2MUnitDiv]> {
  let Latency = 12;  // Conservative estimate for N ~ 7
  let ReleaseAtCycles = [12];
}

// MAC - Lpipe only (1-1-3)
def : WriteRes<WriteIMAC, [V850E2MLpipe]> { let Latency = 3; }

// Memory operations - Lpipe only
// Load latency: 1-1-3 (all load sizes)
def : WriteRes<WriteLDB, [V850E2MLpipe]> { let Latency = 3; }
def : WriteRes<WriteLDH, [V850E2MLpipe]> { let Latency = 3; }
def : WriteRes<WriteLDW, [V850E2MLpipe]> { let Latency = 3; }
// Store latency: 1-1-1
def : WriteRes<WriteSTB, [V850E2MLpipe]>;
def : WriteRes<WriteSTH, [V850E2MLpipe]>;
def : WriteRes<WriteSTW, [V850E2MLpipe]>;

// Branch operations - Branch unit (4-4-4 for taken branches)
def : WriteRes<WriteJmp, [V850E2MUnitBranch]> { let Latency = 4; }
def : WriteRes<WriteJal, [V850E2MUnitBranch]> { let Latency = 4; }
def : WriteRes<WriteBranch, [V850E2MUnitBranch]> { let Latency = 4; }

// Special instructions
def : WriteRes<WriteNop, []>;
// LDSR: varies by register (1-4), STSR: 1-1-1
def : WriteRes<WriteSys, [V850E2MAnyPipe]> { let Latency = 4; }

// PREPARE: n+2 cycles (n = registers in list)
def : WriteRes<WritePREPARE, [V850E2MLpipe]> {
  let Latency = 4;
  let ReleaseAtCycles = [4];
}

// DISPOSE: n+2 to n+6 cycles depending on variant
def : WriteRes<WriteDISPOSE, [V850E2MLpipe]> {
  let Latency = 4;
  let ReleaseAtCycles = [4];
}

// CALLT: 10-10-10
def : WriteRes<WriteCALLT, [V850E2MUnitBranch]> { let Latency = 10; }

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

// FP load - uses Lpipe (same as integer loads, 1-1-3)
def : WriteRes<WriteFLD32, [V850E2MLpipe]> { let Latency = 3; }
def : WriteRes<WriteFLD64, [V850E2MLpipe]> { let Latency = 3; }

// FP store - uses Lpipe (1-1-1)
def : WriteRes<WriteFST32, [V850E2MLpipe]>;
def : WriteRes<WriteFST64, [V850E2MLpipe]>;

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
