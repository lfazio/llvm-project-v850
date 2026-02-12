//===-- V850Schedule.td - V850 Scheduling Definitions ------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file describes the V850 scheduling model.
//
// V850 is an in-order processor with simple pipeline. This scheduling model
// provides instruction latencies and resource usage for better code scheduling.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Define scheduler resources associated with def operands (writes).
//===----------------------------------------------------------------------===//

// Integer ALU operations
def WriteIALU       : SchedWrite;    // Integer ALU (add, sub, and, or, xor, etc.)
def WriteIALUimm    : SchedWrite;    // Integer ALU with immediate
def WriteShift      : SchedWrite;    // Shift operations (shl, shr, sar)
def WriteShiftReg   : SchedWrite;    // Shift by register (V850XI format)
def WriteMOV        : SchedWrite;    // Move operations
def WriteCMP        : SchedWrite;    // Compare operations

// Integer multiply/divide
def WriteIMul       : SchedWrite;    // Integer multiply (2 cycles)
def WriteIDiv       : SchedWrite;    // Integer divide (36 cycles)
def WriteIDivQ      : SchedWrite;    // Quick divide (N+5 cycles, ~20 average)
def WriteIMAC       : SchedWrite;    // Multiply-accumulate (3 cycles)

// Extension operations
def WriteExt        : SchedWrite;    // Sign/zero extension (SXB, SXH, ZXB, ZXH)
def WriteBSW        : SchedWrite;    // Byte swap operations

// Memory operations
def WriteLDB        : SchedWrite;    // Load byte
def WriteLDH        : SchedWrite;    // Load halfword
def WriteLDW        : SchedWrite;    // Load word
def WriteSTB        : SchedWrite;    // Store byte
def WriteSTH        : SchedWrite;    // Store halfword
def WriteSTW        : SchedWrite;    // Store word

// Branch/Jump operations
def WriteJmp        : SchedWrite;    // Unconditional jump
def WriteJal        : SchedWrite;    // Jump and link (call)
def WriteBranch     : SchedWrite;    // Conditional branch

// Control operations
def WriteNop        : SchedWrite;    // No operation
def WriteSys        : SchedWrite;    // System instructions (LDSR, STSR, etc.)

// Bit manipulation
def WriteBit        : SchedWrite;    // Bit operations (SET1, CLR1, NOT1, TST1)
def WriteSCH        : SchedWrite;    // Search bit operations

// Saturating arithmetic
def WriteSat        : SchedWrite;    // Saturating add/sub

// Conditional move
def WriteCMOV       : SchedWrite;    // Conditional move

// Special instructions
def WritePREPARE    : SchedWrite;    // PREPARE (prologue)
def WriteDISPOSE    : SchedWrite;    // DISPOSE (epilogue)
def WriteCALLT      : SchedWrite;    // CALLT (table call)

//===----------------------------------------------------------------------===//
// RH850G3M-Specific Write Types
//===----------------------------------------------------------------------===//

def WriteLDDW       : SchedWrite;    // 64-bit load (LD.DW)
def WriteSTDW       : SchedWrite;    // 64-bit store (ST.DW)
def WriteLDLW       : SchedWrite;    // Load linked (LDL.W)
def WriteSTCW       : SchedWrite;    // Store conditional (STC.W)
def WriteROTL       : SchedWrite;    // Rotate left (ROTL)
def WriteBINS       : SchedWrite;    // Bitfield insert (BINS)
def WritePUSHSP     : SchedWrite;    // Push to stack (PUSHSP)
def WritePOPSP      : SchedWrite;    // Pop from stack (POPSP)
def WriteLOOP       : SchedWrite;    // Hardware loop (LOOP)
def WriteCACHE      : SchedWrite;    // Cache operation (CACHE)
def WriteG3MPREF    : SchedWrite;    // Prefetch (PREF)
def WriteSYNCI      : SchedWrite;    // Instruction sync (SYNCI)
def WriteSNOOZE     : SchedWrite;    // Low-power snooze (SNOOZE)
def WriteCLL        : SchedWrite;    // Clear load link (CLL)

//===----------------------------------------------------------------------===//
// FPU Write Types (V850E2M only)
//===----------------------------------------------------------------------===//

def WriteFAdd32     : SchedWrite;    // Single-precision add/sub
def WriteFAdd64     : SchedWrite;    // Double-precision add/sub
def WriteFMul32     : SchedWrite;    // Single-precision multiply
def WriteFMul64     : SchedWrite;    // Double-precision multiply
def WriteFDiv32     : SchedWrite;    // Single-precision divide (~35 cycles)
def WriteFDiv64     : SchedWrite;    // Double-precision divide (~64 cycles)
def WriteFSqrt32    : SchedWrite;    // Single-precision sqrt (~30 cycles)
def WriteFSqrt64    : SchedWrite;    // Double-precision sqrt (~60 cycles)
def WriteFMA32      : SchedWrite;    // Single-precision fused multiply-add
def WriteFMA64      : SchedWrite;    // Double-precision fused multiply-add
def WriteFCmp       : SchedWrite;    // FP compare
def WriteFCvt       : SchedWrite;    // FP conversion (CVTF.*, TRNCF.*, etc.)
def WriteFMov       : SchedWrite;    // FP move (ABSF, NEGF, etc.)
def WriteFMinMax    : SchedWrite;    // FP min/max
def WriteFLD32      : SchedWrite;    // Single-precision load
def WriteFLD64      : SchedWrite;    // Double-precision load
def WriteFST32      : SchedWrite;    // Single-precision store
def WriteFST64      : SchedWrite;    // Double-precision store

//===----------------------------------------------------------------------===//
// Define scheduler resources associated with use operands (reads).
//===----------------------------------------------------------------------===//

def ReadIALU        : SchedRead;     // Integer ALU operand
def ReadIMul        : SchedRead;     // Integer multiply operand
def ReadIDiv        : SchedRead;     // Integer divide operand
def ReadIMAC        : SchedRead;     // MAC operand
def ReadMemBase     : SchedRead;     // Memory base address
def ReadStoreData   : SchedRead;     // Store data operand
def ReadJmp         : SchedRead;     // Jump target operand
def ReadBranch      : SchedRead;     // Branch condition operand
def ReadCMOV        : SchedRead;     // CMOV condition operand

// FPU reads
def ReadFAdd        : SchedRead;     // FP add/sub operand
def ReadFMul        : SchedRead;     // FP multiply operand
def ReadFDiv        : SchedRead;     // FP divide operand
def ReadFMA         : SchedRead;     // FMA operand
def ReadFMemBase    : SchedRead;     // FP memory base address
def ReadFStoreData  : SchedRead;     // FP store data operand

//===----------------------------------------------------------------------===//
// V850 Generic Scheduling Model
//
// This is a model for the base V850 processor.
// V850 is an in-order, single-issue processor with 5-stage pipeline:
//   IF (Instruction Fetch) -> ID (Decode) -> EX (Execute) -> MEM -> WB
//
// Timing notation: issue-repeat-latency
//   - issue: cycles before next instruction can start
//   - repeat: cycles when same instruction executes consecutively
//   - latency: cycles before result is available to dependent instruction
//===----------------------------------------------------------------------===//

def V850Model : SchedMachineModel {
  let MicroOpBufferSize = 0;    // V850 is in-order
  let IssueWidth = 1;           // Single-issue
  let LoadLatency = 2;          // Default load latency (1-1-2)
  let MispredictPenalty = 3;    // Branch taken penalty (3 cycles)
  let CompleteModel = false;    // Incomplete model - use defaults for unmodeled instrs
  let PostRAScheduler = true;   // Enable post-RA scheduling for stall reduction
}

//===----------------------------------------------------------------------===//
// Define processor resources for V850
//===----------------------------------------------------------------------===//

let SchedModel = V850Model in {
  let BufferSize = 0 in {
    def V850UnitALU      : ProcResource<1>;  // Integer ALU
    def V850UnitMem      : ProcResource<1>;  // Load/Store unit
    def V850UnitBranch   : ProcResource<1>;  // Branch unit
  }

  let BufferSize = 1 in {
    def V850UnitMul      : ProcResource<1>;  // Integer multiply
    def V850UnitDiv      : ProcResource<1>;  // Integer divide
  }
}

//===----------------------------------------------------------------------===//
// V850 Base Instruction Latencies
//===----------------------------------------------------------------------===//

let SchedModel = V850Model in {

// Integer ALU - 1 cycle latency
def : WriteRes<WriteIALU, [V850UnitALU]>;
def : WriteRes<WriteIALUimm, [V850UnitALU]>;
def : WriteRes<WriteShift, [V850UnitALU]>;
def : WriteRes<WriteShiftReg, [V850UnitALU]>;
def : WriteRes<WriteMOV, [V850UnitALU]>;
def : WriteRes<WriteCMP, [V850UnitALU]>;
def : WriteRes<WriteExt, [V850UnitALU]>;
def : WriteRes<WriteBSW, [V850UnitALU]>;
def : WriteRes<WriteSat, [V850UnitALU]>;
def : WriteRes<WriteBit, [V850UnitALU]>;
def : WriteRes<WriteSCH, [V850UnitALU]>;
def : WriteRes<WriteCMOV, [V850UnitALU]>;

// Integer multiply - MULH is 1-1-2 on base V850
def : WriteRes<WriteIMul, [V850UnitMul]> { let Latency = 2; }

// Integer divide - DIVH is 36-36-36 on base V850
def : WriteRes<WriteIDiv, [V850UnitDiv]> {
  let Latency = 36;
  let ReleaseAtCycles = [36];
}

// Quick divide (DIVQ/DIVQU) - not available on base V850
// Marked as unsupported - will use default scheduling
let Unsupported = true in
def : WriteRes<WriteIDivQ, [V850UnitDiv]> {
  let Latency = 20;
  let ReleaseAtCycles = [20];
}

// MAC - not available on base V850
let Unsupported = true in
def : WriteRes<WriteIMAC, [V850UnitMul]> { let Latency = 3; }

// Memory operations - V850 base: LD.* is 1-1-2, ST.* is 1-1-1
def : WriteRes<WriteLDB, [V850UnitMem]> { let Latency = 2; }
def : WriteRes<WriteLDH, [V850UnitMem]> { let Latency = 2; }
def : WriteRes<WriteLDW, [V850UnitMem]> { let Latency = 2; }
def : WriteRes<WriteSTB, [V850UnitMem]>;
def : WriteRes<WriteSTH, [V850UnitMem]>;
def : WriteRes<WriteSTW, [V850UnitMem]>;

// Branch operations - V850 base: JMP/JR/JARL are 3-3-3, Bcond taken is 3-3-3
def : WriteRes<WriteJmp, [V850UnitBranch]> { let Latency = 3; }
def : WriteRes<WriteJal, [V850UnitBranch]> { let Latency = 3; }
def : WriteRes<WriteBranch, [V850UnitBranch]> { let Latency = 3; }

// Special instructions
def : WriteRes<WriteNop, []>;
def : WriteRes<WriteSys, [V850UnitALU]>;  // LDSR/STSR: 1-1-1 (3 for EIPC/FEPC)

// PREPARE/DISPOSE/CALLT - not available on base V850
// Marked as unsupported - will use default scheduling
let Unsupported = true in {
  def : WriteRes<WritePREPARE, [V850UnitMem]> { let Latency = 4; }
  def : WriteRes<WriteDISPOSE, [V850UnitMem]> { let Latency = 4; }
  def : WriteRes<WriteCALLT, [V850UnitBranch]> { let Latency = 4; }
}

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

// G3M write resources - mark as unsupported for base V850
let Unsupported = true in {
  def : WriteRes<WriteLDDW, []>;
  def : WriteRes<WriteSTDW, []>;
  def : WriteRes<WriteLDLW, []>;
  def : WriteRes<WriteSTCW, []>;
  def : WriteRes<WriteROTL, []>;
  def : WriteRes<WriteBINS, []>;
  def : WriteRes<WritePUSHSP, []>;
  def : WriteRes<WritePOPSP, []>;
  def : WriteRes<WriteLOOP, []>;
  def : WriteRes<WriteCACHE, []>;
  def : WriteRes<WriteG3MPREF, []>;
  def : WriteRes<WriteSYNCI, []>;
  def : WriteRes<WriteSNOOZE, []>;
  def : WriteRes<WriteCLL, []>;
}

// FPU write resources - mark as unsupported for base V850
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

// FPU read advances - mark as unsupported for base V850
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

} // SchedModel = V850Model
