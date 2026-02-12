//===-- V850SchedRH850G3M.td - RH850G3M Scheduling Defs ----*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file describes the RH850G3M scheduling model.
//
// The RH850G3M is based on the V850E2M dual-issue pipeline but with
// significant performance improvements:
//
// Key differences from V850E2M:
//   - Branch prediction: 1 cycle when predicted, 4 cycles on mispredict
//   - Division: 19 cycles (vs 36 on V850E2M)
//   - DIVQ/DIVQU: N+3 cycles (vs N+5 on V850E2M), N in range 0-16
//   - FPU divide/sqrt significantly faster:
//       DIVF.S: 14 (vs 35), SQRTF.S: 14 (vs 30)
//       DIVF.D: 30 (vs 64), SQRTF.D: 30 (vs 60)
//   - RECIPF.S: 10, RECIPF.D: 26, RSQRTF.S: 14, RSQRTF.D: 36
//   - LDSR: 3 cycles (vs 4)
//   - New instructions: LDL.W, STC.W, CLL, ROTL, BINS, LD.DW, ST.DW,
//     LOOP, PUSHSP, POPSP, CACHE, PREF, SYNCI, SNOOZE, Bcond disp17
//
// Source: RH850G3M User's Manual, Appendix B (Instruction Execution Clocks)
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// RH850G3M Scheduling Model
//===----------------------------------------------------------------------===//

def RH850G3MModel : SchedMachineModel {
  let MicroOpBufferSize = 0;    // RH850G3M is in-order
  let IssueWidth = 2;           // Dual-issue superscalar (Lpipe + Rpipe)
  let LoadLatency = 3;          // Default load latency (1-1-3)
  let MispredictPenalty = 4;    // Branch mispredict penalty (4 cycles)
  let CompleteModel = false;    // Incomplete model
  let PostRAScheduler = true;   // Enable post-RA scheduling for dual-issue
}

//===----------------------------------------------------------------------===//
// Define processor resources for RH850G3M
//
// Same dual-issue pipeline structure as V850E2M:
//   Lpipe: Load/store, multiply, MAC
//   Rpipe: ALU, shift, data manipulation, bit search
//   Both: Many arithmetic/logical operations can use either pipe
//===----------------------------------------------------------------------===//

let SchedModel = RH850G3MModel in {
  let BufferSize = 0 in {
    def G3MLpipe        : ProcResource<1>;  // L-pipe (load/store, mul, MAC)
    def G3MRpipe        : ProcResource<1>;  // R-pipe (ALU, shift, bit search)
    def G3MAnyPipe      : ProcResource<2>;  // Either pipe (most ALU ops)
    def G3MUnitBranch   : ProcResource<1>;  // Branch unit
    def G3MUnitFPALU    : ProcResource<1>;  // FP ALU (add, sub, mul, cmp, cvt)
  }

  let BufferSize = 1 in {
    def G3MUnitDiv      : ProcResource<1>;  // Integer divide (blocking)
    def G3MUnitFPDiv    : ProcResource<1>;  // FP divide/sqrt (not pipelined)
  }

  def G3MLpipeGroup : ProcResGroup<[G3MLpipe]>;
  def G3MRpipeGroup : ProcResGroup<[G3MRpipe]>;
}

//===----------------------------------------------------------------------===//
// RH850G3M Integer Instruction Latencies
//===----------------------------------------------------------------------===//

let SchedModel = RH850G3MModel in {

// Integer ALU - 1 cycle latency (1-1-1), either pipe
def : WriteRes<WriteIALU, [G3MAnyPipe]>;
def : WriteRes<WriteIALUimm, [G3MAnyPipe]>;
def : WriteRes<WriteMOV, [G3MAnyPipe]>;
def : WriteRes<WriteCMP, [G3MAnyPipe]>;
def : WriteRes<WriteSat, [G3MAnyPipe]>;      // SATADD/SATSUB

// Shift operations - Rpipe only (1-1-1)
def : WriteRes<WriteShift, [G3MRpipe]>;
def : WriteRes<WriteShiftReg, [G3MRpipe]>;

// Data manipulation - Rpipe only (1-1-1)
def : WriteRes<WriteExt, [G3MRpipe]>;        // SXB, SXH, ZXB, ZXH
def : WriteRes<WriteBSW, [G3MRpipe]>;        // BSH, BSW, HSH, HSW

// Bit search - Rpipe only (1-1-1)
def : WriteRes<WriteSCH, [G3MRpipe]>;        // SCH0L, SCH0R, SCH1L, SCH1R

// Conditional move - either pipe (1-1-1)
def : WriteRes<WriteCMOV, [G3MAnyPipe]>;     // CMOV, ADF, SBF

// Bit manipulation - uses Lpipe for memory access (4-4-4)
def : WriteRes<WriteBit, [G3MLpipe]> { let Latency = 4; }

// Integer multiply - Lpipe only (1-1-3)
def : WriteRes<WriteIMul, [G3MLpipe]> { let Latency = 3; }

// Integer divide - 19 cycles (was 36 on V850E2M)
def : WriteRes<WriteIDiv, [G3MUnitDiv]> {
  let Latency = 19;
  let ReleaseAtCycles = [19];
}

// Quick divide (DIVQ/DIVQU) - N+3 cycles (N ranges 0-16)
// Conservative estimate for average case (~10 cycles)
def : WriteRes<WriteIDivQ, [G3MUnitDiv]> {
  let Latency = 10;
  let ReleaseAtCycles = [10];
}

// MAC - Lpipe only (1-1-3)
def : WriteRes<WriteIMAC, [G3MLpipe]> { let Latency = 3; }

// Memory operations - Lpipe only
// Load latency: 1-1-3 (all load sizes)
def : WriteRes<WriteLDB, [G3MLpipe]> { let Latency = 3; }
def : WriteRes<WriteLDH, [G3MLpipe]> { let Latency = 3; }
def : WriteRes<WriteLDW, [G3MLpipe]> { let Latency = 3; }
// Store latency: 1-1-1
def : WriteRes<WriteSTB, [G3MLpipe]>;
def : WriteRes<WriteSTH, [G3MLpipe]>;
def : WriteRes<WriteSTW, [G3MLpipe]>;

// Branch operations
// G3M has branch prediction: 1 cycle predicted, 4 cycles mispredict
// Model with average latency of 4 (worst case) for unconditional
def : WriteRes<WriteJmp, [G3MUnitBranch]> { let Latency = 4; }
def : WriteRes<WriteJal, [G3MUnitBranch]> { let Latency = 4; }
// Conditional branches benefit from prediction (average ~2 cycles)
def : WriteRes<WriteBranch, [G3MUnitBranch]> { let Latency = 4; }

// Special instructions
def : WriteRes<WriteNop, []>;
// LDSR: 3-3-3 (was 4 on V850E2M), STSR: 1-1-1
def : WriteRes<WriteSys, [G3MAnyPipe]> { let Latency = 3; }

// PREPARE: n+2 cycles (n = registers in list)
def : WriteRes<WritePREPARE, [G3MLpipe]> {
  let Latency = 4;
  let ReleaseAtCycles = [4];
}

// DISPOSE: n+2 to n+6 cycles depending on variant
def : WriteRes<WriteDISPOSE, [G3MLpipe]> {
  let Latency = 4;
  let ReleaseAtCycles = [4];
}

// CALLT: 10-10-10
def : WriteRes<WriteCALLT, [G3MUnitBranch]> { let Latency = 10; }

//===----------------------------------------------------------------------===//
// RH850G3M-Specific Instruction Latencies
//===----------------------------------------------------------------------===//

// LD.DW - 64-bit load (48-bit instruction, cannot dual-issue)
// Latency: 1-1-3 (like regular load but 6-byte instruction)
def : WriteRes<WriteLDDW, [G3MLpipe]> { let Latency = 3; }

// ST.DW - 64-bit store (48-bit instruction, cannot dual-issue)
def : WriteRes<WriteSTDW, [G3MLpipe]>;

// LDL.W - Load linked word (exclusive access, 1-1-3)
def : WriteRes<WriteLDLW, [G3MLpipe]> { let Latency = 3; }

// STC.W - Store conditional word (1-1-1)
def : WriteRes<WriteSTCW, [G3MLpipe]>;

// CLL - Clear load link (1-1-1)
def : WriteRes<WriteCLL, [G3MAnyPipe]>;

// ROTL - Rotate left (1-1-1, data operation, Rpipe)
def : WriteRes<WriteROTL, [G3MRpipe]>;

// BINS - Bitfield insert (1-1-1, data operation)
def : WriteRes<WriteBINS, [G3MRpipe]>;

// PUSHSP - Push registers to stack (n+2 cycles, Lpipe)
def : WriteRes<WritePUSHSP, [G3MLpipe]> {
  let Latency = 4;
  let ReleaseAtCycles = [4];
}

// POPSP - Pop registers from stack (n+2 cycles, Lpipe)
def : WriteRes<WritePOPSP, [G3MLpipe]> {
  let Latency = 4;
  let ReleaseAtCycles = [4];
}

// LOOP - Hardware loop (1 cycle predicted, 4 cycles mispredict)
def : WriteRes<WriteLOOP, [G3MUnitBranch]> { let Latency = 4; }

// CACHE - Cache operation (1-1-undefined latency)
def : WriteRes<WriteCACHE, [G3MLpipe]>;

// PREF - Prefetch (1-1-1)
def : WriteRes<WriteG3MPREF, [G3MLpipe]>;

// SYNCI - Instruction sync (1-1-undefined, blocking)
def : WriteRes<WriteSYNCI, [G3MAnyPipe]>;

// SNOOZE - Low-power snooze (undefined, blocking)
def : WriteRes<WriteSNOOZE, []>;

//===----------------------------------------------------------------------===//
// RH850G3M FPU Instruction Latencies
//
// G3M FPU is significantly faster than V850E2M for divide/sqrt:
//   ADDF.S/SUBF.S: 4 cycles (imprecise mode)
//   ADDF.D/SUBF.D: 4 cycles
//   MULF.S: 4 cycles
//   MULF.D: 5 cycles (2-2-5)
//   DIVF.S: 14 cycles (was 35 on V850E2M)
//   DIVF.D: 30 cycles (was 64 on V850E2M)
//   SQRTF.S: 14 cycles (was 30 on V850E2M)
//   SQRTF.D: 30 cycles (was 60 on V850E2M)
//   RECIPF.S: 10 cycles
//   RECIPF.D: 26 cycles
//   RSQRTF.S: 14 cycles
//   RSQRTF.D: 36 cycles
//   FMA: same as add/mul (4 cycles SP, 5 cycles DP)
//
// Source: RH850G3M User's Manual, Appendix B, Tables 3-4
//===----------------------------------------------------------------------===//

// Single-precision FP add/sub - 4 cycles
def : WriteRes<WriteFAdd32, [G3MUnitFPALU]> { let Latency = 4; }

// Double-precision FP add/sub - 4 cycles
def : WriteRes<WriteFAdd64, [G3MUnitFPALU]> { let Latency = 4; }

// Single-precision FP multiply - 4 cycles
def : WriteRes<WriteFMul32, [G3MUnitFPALU]> { let Latency = 4; }

// Double-precision FP multiply - 5 cycles (2-2-5)
def : WriteRes<WriteFMul64, [G3MUnitFPALU]> { let Latency = 5; }

// Single-precision FP divide - 14 cycles (was 35 on V850E2M)
def : WriteRes<WriteFDiv32, [G3MUnitFPDiv]> {
  let Latency = 14;
  let ReleaseAtCycles = [14];
}

// Double-precision FP divide - 30 cycles (was 64 on V850E2M)
def : WriteRes<WriteFDiv64, [G3MUnitFPDiv]> {
  let Latency = 30;
  let ReleaseAtCycles = [30];
}

// Single-precision FP sqrt - 14 cycles (was 30 on V850E2M)
def : WriteRes<WriteFSqrt32, [G3MUnitFPDiv]> {
  let Latency = 14;
  let ReleaseAtCycles = [14];
}

// Double-precision FP sqrt - 30 cycles (was 60 on V850E2M)
def : WriteRes<WriteFSqrt64, [G3MUnitFPDiv]> {
  let Latency = 30;
  let ReleaseAtCycles = [30];
}

// Single-precision FMA - 4 cycles
def : WriteRes<WriteFMA32, [G3MUnitFPALU]> { let Latency = 4; }

// Double-precision FMA - 5 cycles
def : WriteRes<WriteFMA64, [G3MUnitFPALU]> { let Latency = 5; }

// FP compare - 4 cycles (imprecise mode)
def : WriteRes<WriteFCmp, [G3MUnitFPALU]> { let Latency = 4; }

// FP conversion - 4 cycles
def : WriteRes<WriteFCvt, [G3MUnitFPALU]> { let Latency = 4; }

// FP move (ABSF, NEGF) - 4 cycles (imprecise mode)
def : WriteRes<WriteFMov, [G3MUnitFPALU]> { let Latency = 4; }

// FP min/max - 4 cycles
def : WriteRes<WriteFMinMax, [G3MUnitFPALU]> { let Latency = 4; }

// FP load - uses Lpipe (1-1-3)
def : WriteRes<WriteFLD32, [G3MLpipe]> { let Latency = 3; }
def : WriteRes<WriteFLD64, [G3MLpipe]> { let Latency = 3; }

// FP store - uses Lpipe (1-1-1)
def : WriteRes<WriteFST32, [G3MLpipe]>;
def : WriteRes<WriteFST64, [G3MLpipe]>;

//===----------------------------------------------------------------------===//
// InstRW overrides for G3M-specific instructions
//===----------------------------------------------------------------------===//

// G3M-specific instructions
def : InstRW<[WriteLDDW], (instrs LD_DW)>;
def : InstRW<[WriteSTDW], (instrs ST_DW)>;
def : InstRW<[WriteLDLW], (instrs LDL_W)>;
def : InstRW<[WriteSTCW], (instrs STC_W)>;
def : InstRW<[WriteCLL], (instrs CLL)>;
def : InstRW<[WriteROTL], (instrs ROTL_imm, ROTL_reg)>;
def : InstRW<[WriteBINS], (instrs BINS0, BINS1, BINS2)>;
def : InstRW<[WritePUSHSP], (instrs PUSHSP)>;
def : InstRW<[WritePOPSP], (instrs POPSP)>;
def : InstRW<[WriteLOOP], (instrs LOOP)>;
def : InstRW<[WriteCACHE], (instrs CACHE)>;
def : InstRW<[WriteG3MPREF], (instrs PREF)>;
def : InstRW<[WriteSYNCI], (instrs SYNCI)>;
def : InstRW<[WriteSNOOZE], (instrs SNOOZE)>;

// Bcond17 instructions (branch with 17-bit displacement)
def : InstRW<[WriteBranch], (instrs BV_17, BC_17, BZ_17, BNH_17, BN_17,
                                     BLT_17, BLE_17, BNV_17, BNC_17, BNZ_17,
                                     BH_17, BP_17, BSA_17, BGE_17, BGT_17)>;

// RECIPF/RSQRTF have different latencies from DIVF/SQRTF on G3M
// RECIPF.S: 10 cycles, RSQRTF.S: 14 cycles
// RECIPF.D: 26 cycles, RSQRTF.D: 36 cycles
def G3MWriteFRecip32 : SchedWriteRes<[G3MUnitFPDiv]> {
  let Latency = 10;
  let ReleaseAtCycles = [10];
}
def G3MWriteFRecip64 : SchedWriteRes<[G3MUnitFPDiv]> {
  let Latency = 26;
  let ReleaseAtCycles = [26];
}
def G3MWriteFRSqrt32 : SchedWriteRes<[G3MUnitFPDiv]> {
  let Latency = 14;
  let ReleaseAtCycles = [14];
}
def G3MWriteFRSqrt64 : SchedWriteRes<[G3MUnitFPDiv]> {
  let Latency = 36;
  let ReleaseAtCycles = [36];
}

def : InstRW<[G3MWriteFRecip32], (instrs RECIPFS)>;
def : InstRW<[G3MWriteFRecip64], (instrs RECIPFD)>;
def : InstRW<[G3MWriteFRSqrt32], (instrs RSQRTFS)>;
def : InstRW<[G3MWriteFRSqrt64], (instrs RSQRTFD)>;

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

} // SchedModel = RH850G3MModel
