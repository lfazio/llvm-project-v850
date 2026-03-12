//===-- V850SchedRH850G4MH.td - RH850G4MH Scheduling Defs ---*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file describes the RH850G4MH scheduling model.
//
// The RH850G4MH is based on the RH850G3M dual-issue pipeline with identical
// integer and scalar FPU timings. The key additions are:
//
//   - Post-increment/decrement load/store (same latency as regular LD/ST)
//   - CLIP saturation instructions (1 cycle)
//   - FXU 128-bit SIMD vector unit (wreg0-wreg31):
//       ADDF.S4/SUBF.S4: 4 cycles, MULF.S4: 4 cycles
//       DIVF.S4: 14 cycles, SQRTF.S4: 14 cycles
//       RECIPF.S4: 10 cycles, RSQRTF.S4: 14 cycles
//       FMAF.S4/FMSF.S4/FNMAF.S4/FNMSF.S4: 4 cycles
//       CVTF.*: 4 cycles, LDV.QW: 2 cycles, STV.QW: 1 cycle
//   - MPU bulk operations: LDM.MP (N+8), STM.MP (N+2)
//   - Virtualization: HVTRAP, LDM.GSR, STM.GSR
//
// Source: RH850G4MH User's Manual, instruction timing tables
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// RH850G4MH Scheduling Model
//===----------------------------------------------------------------------===//

def RH850G4MHModel : SchedMachineModel {
  let MicroOpBufferSize = 0;  // RH850G4MH is in-order
  let IssueWidth = 2;         // Dual-issue superscalar (Lpipe + Rpipe)
  let LoadLatency = 3;        // Default load latency (1-1-3)
  let MispredictPenalty = 4;  // Branch mispredict penalty (4 cycles)
  let CompleteModel = false;  // Incomplete model
  let PostRAScheduler = true; // Enable post-RA scheduling for dual-issue
}

//===----------------------------------------------------------------------===//
// Define processor resources for RH850G4MH
//
// Same dual-issue pipeline structure as G3M plus FXU coprocessor:
//   Lpipe: Load/store, multiply, MAC
//   Rpipe: ALU, shift, data manipulation, bit search
//   Both: Many arithmetic/logical operations can use either pipe
//   FXU: SIMD vector unit (separate from scalar FPU)
//===----------------------------------------------------------------------===//

let SchedModel = RH850G4MHModel in {
  let BufferSize = 0 in {
    def G4MHLpipe : ProcResource<1>;      // L-pipe (load/store, mul, MAC)
    def G4MHRpipe : ProcResource<1>;      // R-pipe (ALU, shift, bit search)
    def G4MHAnyPipe : ProcResource<2>;    // Either pipe (most ALU ops)
    def G4MHUnitBranch : ProcResource<1>; // Branch unit
    def G4MHUnitFPALU : ProcResource<1>;  // Scalar FP ALU (add, sub, mul, cmp, cvt)
    def G4MHUnitFXU : ProcResource<1>;    // FXU SIMD ALU (4xf32 operations)
  }

  let BufferSize = 1 in {
    def G4MHUnitDiv : ProcResource<1>;    // Integer divide (blocking)
    def G4MHUnitFPDiv : ProcResource<1>;  // Scalar FP divide/sqrt (not pipelined)
    def G4MHUnitFXUDiv : ProcResource<1>; // FXU SIMD divide/sqrt (not pipelined)
  }
}

//===----------------------------------------------------------------------===//
// RH850G4MH Integer Instruction Latencies
// (Same as G3M — identical integer pipeline)
//===----------------------------------------------------------------------===//

let SchedModel = RH850G4MHModel in {

  // Integer ALU - 1 cycle latency (1-1-1), either pipe
  def : WriteRes<WriteIALU, [G4MHAnyPipe]>;
  def : WriteRes<WriteIALUimm, [G4MHAnyPipe]>;
  def : WriteRes<WriteMOV, [G4MHAnyPipe]>;
  def : WriteRes<WriteCMP, [G4MHAnyPipe]>;
  def : WriteRes<WriteSat, [G4MHAnyPipe]>; // SATADD/SATSUB

  // Shift operations - Rpipe only (1-1-1)
  def : WriteRes<WriteShift, [G4MHRpipe]>;
  def : WriteRes<WriteShiftReg, [G4MHRpipe]>;

  // Data manipulation - Rpipe only (1-1-1)
  def : WriteRes<WriteExt, [G4MHRpipe]>; // SXB, SXH, ZXB, ZXH
  def : WriteRes<WriteBSW, [G4MHRpipe]>; // BSH, BSW, HSH, HSW

  // Bit search - Rpipe only (1-1-1)
  def : WriteRes<WriteSCH, [G4MHRpipe]>; // SCH0L, SCH0R, SCH1L, SCH1R

  // Conditional move - either pipe (1-1-1)
  def : WriteRes<WriteCMOV, [G4MHAnyPipe]>; // CMOV, ADF, SBF

  // Bit manipulation - uses Lpipe for memory access (4-4-4)
  def : WriteRes<WriteBit, [G4MHLpipe]> { let Latency = 4; }

  // Integer multiply - Lpipe only (1-1-3)
  def : WriteRes<WriteIMul, [G4MHLpipe]> { let Latency = 3; }

  // Integer divide - 19 cycles (same as G3M)
  def : WriteRes<WriteIDiv, [G4MHUnitDiv]> {
    let Latency = 19;
    let ReleaseAtCycles = [19];
  }

  // Quick divide (DIVQ/DIVQU) - N+3 cycles
  def : WriteRes<WriteIDivQ, [G4MHUnitDiv]> {
    let Latency = 10;
    let ReleaseAtCycles = [10];
  }

  // MAC - Lpipe only (1-1-3)
  def : WriteRes<WriteIMAC, [G4MHLpipe]> { let Latency = 3; }

  // Memory operations - Lpipe only
  def : WriteRes<WriteLDB, [G4MHLpipe]> { let Latency = 3; }
  def : WriteRes<WriteLDH, [G4MHLpipe]> { let Latency = 3; }
  def : WriteRes<WriteLDW, [G4MHLpipe]> { let Latency = 3; }
  def : WriteRes<WriteSTB, [G4MHLpipe]>;
  def : WriteRes<WriteSTH, [G4MHLpipe]>;
  def : WriteRes<WriteSTW, [G4MHLpipe]>;

  // Branch operations
  def : WriteRes<WriteJmp, [G4MHUnitBranch]> { let Latency = 4; }
  def : WriteRes<WriteJal, [G4MHUnitBranch]> { let Latency = 4; }
  def : WriteRes<WriteBranch, [G4MHUnitBranch]> { let Latency = 4; }

  // Special instructions
  def : WriteRes<WriteNop, []>;
  def : WriteRes<WriteSys, [G4MHAnyPipe]> { let Latency = 3; }

  // PREPARE/DISPOSE
  def : WriteRes<WritePREPARE, [G4MHLpipe]> {
    let Latency = 4;
    let ReleaseAtCycles = [4];
  }
  def : WriteRes<WriteDISPOSE, [G4MHLpipe]> {
    let Latency = 4;
    let ReleaseAtCycles = [4];
  }

  // CALLT
  def : WriteRes<WriteCALLT, [G4MHUnitBranch]> { let Latency = 10; }

  //===----------------------------------------------------------------------===//
  // G3M-Inherited Instruction Latencies
  //===----------------------------------------------------------------------===//

  def : WriteRes<WriteLDDW, [G4MHLpipe]> { let Latency = 3; }
  def : WriteRes<WriteSTDW, [G4MHLpipe]>;
  def : WriteRes<WriteLDLW, [G4MHLpipe]> { let Latency = 3; }
  def : WriteRes<WriteSTCW, [G4MHLpipe]>;
  def : WriteRes<WriteCLL, [G4MHAnyPipe]>;
  def : WriteRes<WriteROTL, [G4MHRpipe]>;
  def : WriteRes<WriteBINS, [G4MHRpipe]>;
  def : WriteRes<WritePUSHSP, [G4MHLpipe]> {
    let Latency = 4;
    let ReleaseAtCycles = [4];
  }
  def : WriteRes<WritePOPSP, [G4MHLpipe]> {
    let Latency = 4;
    let ReleaseAtCycles = [4];
  }
  def : WriteRes<WriteLOOP, [G4MHUnitBranch]> { let Latency = 4; }
  def : WriteRes<WriteCACHE, [G4MHLpipe]>;
  def : WriteRes<WriteG3MPREF, [G4MHLpipe]>;
  def : WriteRes<WriteSYNCI, [G4MHAnyPipe]>;
  def : WriteRes<WriteSNOOZE, []>;

  //===----------------------------------------------------------------------===//
  // Scalar FPU Instruction Latencies (same as G3M)
  //===----------------------------------------------------------------------===//

  def : WriteRes<WriteFAdd32, [G4MHUnitFPALU]> { let Latency = 4; }
  def : WriteRes<WriteFAdd64, [G4MHUnitFPALU]> { let Latency = 4; }
  def : WriteRes<WriteFMul32, [G4MHUnitFPALU]> { let Latency = 4; }
  def : WriteRes<WriteFMul64, [G4MHUnitFPALU]> { let Latency = 5; }
  def : WriteRes<WriteFDiv32, [G4MHUnitFPDiv]> {
    let Latency = 14;
    let ReleaseAtCycles = [14];
  }
  def : WriteRes<WriteFDiv64, [G4MHUnitFPDiv]> {
    let Latency = 30;
    let ReleaseAtCycles = [30];
  }
  def : WriteRes<WriteFSqrt32, [G4MHUnitFPDiv]> {
    let Latency = 14;
    let ReleaseAtCycles = [14];
  }
  def : WriteRes<WriteFSqrt64, [G4MHUnitFPDiv]> {
    let Latency = 30;
    let ReleaseAtCycles = [30];
  }
  def : WriteRes<WriteFMA32, [G4MHUnitFPALU]> { let Latency = 4; }
  def : WriteRes<WriteFMA64, [G4MHUnitFPALU]> { let Latency = 5; }
  def : WriteRes<WriteFCmp, [G4MHUnitFPALU]> { let Latency = 4; }
  def : WriteRes<WriteFCvt, [G4MHUnitFPALU]> { let Latency = 4; }
  def : WriteRes<WriteFMov, [G4MHUnitFPALU]> { let Latency = 4; }
  def : WriteRes<WriteFMinMax, [G4MHUnitFPALU]> { let Latency = 4; }
  def : WriteRes<WriteFLD32, [G4MHLpipe]> { let Latency = 3; }
  def : WriteRes<WriteFLD64, [G4MHLpipe]> { let Latency = 3; }
  def : WriteRes<WriteFST32, [G4MHLpipe]>;
  def : WriteRes<WriteFST64, [G4MHLpipe]>;

  //===----------------------------------------------------------------------===//
  // G3M-Inherited InstRW Overrides
  //===----------------------------------------------------------------------===//

  // G3M-specific instructions
  def : InstRW<[WriteLDDW], (instrs LD_DW)>;
  def : InstRW<[WriteSTDW], (instrs ST_DW)>;
  def : InstRW<[WriteLDLW], (instrs LDL_W)>;
  def : InstRW<[WriteSTCW], (instrs STC_W)>;
  def : InstRW<[WriteCLL], (instrs CLL)>;
  def : InstRW<[WriteROTL], (instrs ROTL_imm, ROTL_reg)>;
  def : InstRW<[WriteBINS], (instrs BINS0, BINS1, BINS2, BINS_pseudo)>;
  def : InstRW<[WritePUSHSP], (instrs PUSHSP)>;
  def : InstRW<[WritePOPSP], (instrs POPSP)>;
  def : InstRW<[WriteLOOP], (instrs LOOP)>;
  def : InstRW<[WriteCACHE], (instrs CACHE)>;
  def : InstRW<[WriteG3MPREF], (instrs PREF)>;
  def : InstRW<[WriteSYNCI], (instrs SYNCI)>;
  def : InstRW<[WriteSNOOZE], (instrs SNOOZE)>;

  // Bcond17 instructions
  def : InstRW<[WriteBranch], (instrs BV_17, BC_17, BZ_17, BNH_17, BN_17,
                                  BLT_17, BLE_17, BNV_17, BNC_17, BNZ_17, BH_17,
                                  BP_17, BSA_17, BGE_17, BGT_17)>;

  // Scalar FP RECIPF/RSQRTF (same timings as G3M)
  def G4MHWriteFRecip32 : SchedWriteRes<[G4MHUnitFPDiv]> {
    let Latency = 10;
    let ReleaseAtCycles = [10];
  }
  def G4MHWriteFRecip64 : SchedWriteRes<[G4MHUnitFPDiv]> {
    let Latency = 26;
    let ReleaseAtCycles = [26];
  }
  def G4MHWriteFRSqrt32 : SchedWriteRes<[G4MHUnitFPDiv]> {
    let Latency = 14;
    let ReleaseAtCycles = [14];
  }
  def G4MHWriteFRSqrt64 : SchedWriteRes<[G4MHUnitFPDiv]> {
    let Latency = 36;
    let ReleaseAtCycles = [36];
  }

  def : InstRW<[G4MHWriteFRecip32], (instrs RECIPFS)>;
  def : InstRW<[G4MHWriteFRecip64], (instrs RECIPFD)>;
  def : InstRW<[G4MHWriteFRSqrt32], (instrs RSQRTFS)>;
  def : InstRW<[G4MHWriteFRSqrt64], (instrs RSQRTFD)>;

  // Scalar FPU instruction scheduling
  def : InstRW<[WriteFAdd32], (instrs ADDFS, SUBFS)>;
  def : InstRW<[WriteFMul32], (instrs MULFS)>;
  def : InstRW<[WriteFDiv32], (instrs DIVFS)>;
  def : InstRW<[WriteFSqrt32], (instrs SQRTFS)>;
  def : InstRW<[WriteFMov], (instrs ABSFS, NEGFS)>;
  def : InstRW<[WriteFMinMax], (instrs MAXFS, MINFS)>;
  def : InstRW<[WriteFMA32], (instrs MADDFS, MSUBFS, NMADDFS, NMSUBFS)>;

  def : InstRW<[WriteFAdd64], (instrs ADDFD, SUBFD)>;
  def : InstRW<[WriteFMul64], (instrs MULFD)>;
  def : InstRW<[WriteFDiv64], (instrs DIVFD)>;
  def : InstRW<[WriteFSqrt64], (instrs SQRTFD)>;
  def : InstRW<[WriteFMov], (instrs ABSFD, NEGFD)>;
  def : InstRW<[WriteFMinMax], (instrs MAXFD, MINFD)>;

  def : InstRW<[WriteFCmp], (instrs CMPFS, CMPFD, TRFSR)>;

  def : InstRW<[WriteFCvt], (instrs CVTFDS, CVTFSD, CVTFWS, CVTFUWS, CVTFWD,
                                CVTFUWD,
                                TRNCFSW, TRNCFSUW, TRNCFDW, TRNCFDUW,
                                TRNCFSL, TRNCFSUL, TRNCFDL, TRNCFDUL,
                                CEILFSW, CEILFSUW, CEILFDW, CEILFDUW,
                                CEILFSL, CEILFSUL, CEILFDL, CEILFDUL,
                                FLOORFSW, FLOORFSUW, FLOORFDW, FLOORFDUW,
                                FLOORFSL, FLOORFSUL, FLOORFDL, FLOORFDUL)>;

  def : InstRW<[WriteFLD32], (instrs LDW_F)>;
  def : InstRW<[WriteFST32], (instrs STW_F)>;
  def : InstRW<[WriteFLD64], (instrs LD_DW_F)>;
  def : InstRW<[WriteFST64], (instrs ST_DW_F)>;

  //===----------------------------------------------------------------------===//
  // RH850G4MH-Specific: Post-Increment/Decrement Load/Store
  //
  // Same pipeline latency as regular load/store:
  //   Load: 1-1-3 (3 cycle result latency, plus writeback to base register)
  //   Store: 1-1-1
  //===----------------------------------------------------------------------===//

  def G4MHWritePostIncLD : SchedWriteRes<[G4MHLpipe]> { let Latency = 3; }
  def G4MHWritePostIncST : SchedWriteRes<[G4MHLpipe]>;

  def : InstRW<[G4MHWritePostIncLD], (instrs
    LDB_PostInc, LDB_PostDec, LDBU_PostInc, LDBU_PostDec,
    LDH_PostInc, LDH_PostDec, LDHU_PostInc, LDHU_PostDec,
    LDW_PostInc, LDW_PostDec)>;

  def : InstRW<[G4MHWritePostIncST], (instrs
    STB_PostInc, STB_PostDec,
    STH_PostInc, STH_PostDec,
    STW_PostInc, STW_PostDec)>;

  //===----------------------------------------------------------------------===//
  // RH850G4MH-Specific: CLIP Saturation Instructions
  //
  // 1 cycle latency, either pipe (simple ALU operation)
  //===----------------------------------------------------------------------===//

  def G4MHWriteCLIP : SchedWriteRes<[G4MHAnyPipe]>;

  def : InstRW<[G4MHWriteCLIP], (instrs CLIP_B, CLIP_BU, CLIP_H, CLIP_HU)>;

  //===----------------------------------------------------------------------===//
  // RH850G4MH-Specific: MPU Bulk Operations (G4MH2)
  //
  // LDM.MP: N+8 cycles (N = number of MPU entries)
  // STM.MP: N+2 cycles
  //===----------------------------------------------------------------------===//

  def G4MHWriteLDM_MP : SchedWriteRes<[G4MHLpipe]> {
    let Latency = 12;         // Conservative: ~4 entries typical
    let ReleaseAtCycles = [12];
  }
  def G4MHWriteSTM_MP : SchedWriteRes<[G4MHLpipe]> {
    let Latency = 6;          // Conservative: ~4 entries typical
    let ReleaseAtCycles = [6];
  }

  def : InstRW<[G4MHWriteLDM_MP], (instrs LDM_MP)>;
  def : InstRW<[G4MHWriteSTM_MP], (instrs STM_MP)>;

  //===----------------------------------------------------------------------===//
  // RH850G4MH-Specific: Virtualization Instructions (G4MH2)
  //===----------------------------------------------------------------------===//

  def G4MHWriteHVTRAP : SchedWriteRes<[G4MHUnitBranch]> { let Latency = 10; }
  def G4MHWriteGSR : SchedWriteRes<[G4MHLpipe]> {
    let Latency = 10;
    let ReleaseAtCycles = [10];
  }

  def : InstRW<[G4MHWriteHVTRAP], (instrs HVTRAP)>;
  def : InstRW<[G4MHWriteGSR], (instrs LDM_GSR, STM_GSR)>;

  //===----------------------------------------------------------------------===//
  // RH850G4MH-Specific: FXU SIMD Vector Unit
  //
  // The FXU operates on 128-bit vector registers (wreg0-wreg31), each holding
  // 4 single-precision floats. It has its own execution pipeline separate from
  // the scalar FPU.
  //
  // Timings (from RH850G4MH User's Manual):
  //   Arithmetic (ADDF.S4, SUBF.S4, etc.): 4 cycles
  //   Multiply (MULF.S4): 4 cycles
  //   FMA (FMAF.S4, FMSF.S4, etc.): 4 cycles
  //   Divide (DIVF.S4): 14 cycles (not pipelined)
  //   Sqrt (SQRTF.S4): 14 cycles (not pipelined)
  //   Reciprocal (RECIPF.S4): 10 cycles (not pipelined)
  //   Reciprocal sqrt (RSQRTF.S4): 14 cycles (not pipelined)
  //   Conversion (CVTF.*, TRNCF.*, etc.): 4 cycles
  //   Move/shuffle (MOVV.W4, FLPV.S4, SHFLV.W4): 4 cycles
  //   Comparison (CMPF.S4): 4 cycles
  //   Conditional move (CMOVF.W4): 4 cycles
  //   Load (LDV.QW): 2 cycles
  //   Store (STV.QW): 1 cycle
  //   Min/Max (MAXF.S4, MINF.S4): 4 cycles
  //   Compound/Exchange/Reduction: 4 cycles
  //===----------------------------------------------------------------------===//

  // FXU arithmetic (4 cycles, pipelined)
  def G4MHWriteFXU_ALU : SchedWriteRes<[G4MHUnitFXU]> { let Latency = 4; }

  // FXU divide (14 cycles, not pipelined)
  def G4MHWriteFXU_Div : SchedWriteRes<[G4MHUnitFXUDiv]> {
    let Latency = 14;
    let ReleaseAtCycles = [14];
  }

  // FXU reciprocal (10 cycles, not pipelined)
  def G4MHWriteFXU_Recip : SchedWriteRes<[G4MHUnitFXUDiv]> {
    let Latency = 10;
    let ReleaseAtCycles = [10];
  }

  // FXU reciprocal sqrt (14 cycles, not pipelined)
  def G4MHWriteFXU_RSqrt : SchedWriteRes<[G4MHUnitFXUDiv]> {
    let Latency = 14;
    let ReleaseAtCycles = [14];
  }

  // FXU sqrt (14 cycles, not pipelined)
  def G4MHWriteFXU_Sqrt : SchedWriteRes<[G4MHUnitFXUDiv]> {
    let Latency = 14;
    let ReleaseAtCycles = [14];
  }

  // FXU vector load (2 cycles)
  def G4MHWriteFXU_LD : SchedWriteRes<[G4MHLpipe]> { let Latency = 2; }

  // FXU vector store (1 cycle)
  def G4MHWriteFXU_ST : SchedWriteRes<[G4MHLpipe]>;

  // --- FXU Manipulation ---
  def : InstRW<[G4MHWriteFXU_ALU], (instrs MOVV_W4, FLPV_S4, SHFLV_W4)>;

  // --- FXU Arithmetic ---
  // 2-operand: ABS, NEG (4 cycles)
  def : InstRW<[G4MHWriteFXU_ALU], (instrs ABSF_S4, NEGF_S4)>;
  // 3-operand: ADD, SUB, MUL, MAX, MIN (4 cycles)
  def : InstRW<[G4MHWriteFXU_ALU], (instrs ADDF_S4, SUBF_S4, MULF_S4,
                                       MAXF_S4, MINF_S4)>;
  // Divide (14 cycles, blocking)
  def : InstRW<[G4MHWriteFXU_Div], (instrs DIVF_S4)>;
  // Sqrt (14 cycles, blocking)
  def : InstRW<[G4MHWriteFXU_Sqrt], (instrs SQRTF_S4)>;
  // Reciprocal (10 cycles, blocking)
  def : InstRW<[G4MHWriteFXU_Recip], (instrs RECIPF_S4)>;
  // Reciprocal sqrt (14 cycles, blocking)
  def : InstRW<[G4MHWriteFXU_RSqrt], (instrs RSQRTF_S4)>;

  // --- FXU FMA (4 cycles) ---
  def : InstRW<[G4MHWriteFXU_ALU], (instrs FMAF_S4, FMSF_S4,
                                       FNMAF_S4, FNMSF_S4)>;

  // --- FXU Compound Arithmetic (4 cycles) ---
  def : InstRW<[G4MHWriteFXU_ALU], (instrs ADDSUBF_S4, SUBADDF_S4,
                                       ADDSUBNF_S4, SUBADDNF_S4)>;

  // --- FXU Exchange Arithmetic (4 cycles) ---
  def : InstRW<[G4MHWriteFXU_ALU], (instrs ADDXF_S4, SUBXF_S4, MULXF_S4,
                                       ADDSUBXF_S4, SUBADDXF_S4,
                                       ADDSUBNXF_S4, SUBADDNXF_S4)>;

  // --- FXU Reduction (4 cycles) ---
  def : InstRW<[G4MHWriteFXU_ALU], (instrs ADDRF_S4, SUBRF_S4, MULRF_S4,
                                       MAXRF_S4, MINRF_S4)>;

  // --- FXU Conversion (4 cycles) ---
  def : InstRW<[G4MHWriteFXU_ALU], (instrs
    ROUNDF_SW4, ROUNDF_SUW4,
    TRNCF_SW4, TRNCF_SUW4,
    CEILF_SW4, CEILF_SUW4,
    FLOORF_SW4, FLOORF_SUW4,
    CVTF_SW4, CVTF_SUW4,
    CVTF_WS4, CVTF_UWS4,
    CVTF_HS4, CVTF_SH4)>;

  // --- FXU Comparison (4 cycles) ---
  def : InstRW<[G4MHWriteFXU_ALU], (instrs CMPF_S4, CMOVF_W4, TRFSRV_W4)>;

  // --- FXU Load/Store ---
  def : InstRW<[G4MHWriteFXU_LD], (instrs LDV_W, LDV_DW, LDV_QW, LDVZ_H4)>;
  def : InstRW<[G4MHWriteFXU_ST], (instrs STV_W, STV_DW, STV_DW_E,
                                      STV_QW, STVZ_H4)>;

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

} // SchedModel = RH850G4MHModel
