# V850 Implementation Verification Plan

This document compares the current V850 LLVM backend implementation against the updated V850InstructionReference.md and V850CycleTimings.md documentation and identifies all discrepancies that need to be addressed.

**Date:** 2026-01-10 (Updated)
**Documentation References:**
- docs/V850InstructionReference.md (commit 96e8a965174e)
- docs/V850CycleTimings.md (comprehensive cycle timing specifications)
**Implementation Base:** llvm/lib/Target/V850/

---

## Executive Summary

The V850 backend has comprehensive support for V850, V850ES, V850E1, V850E2, and V850E2M CPU variants with 322 instruction definitions and 71 FPU instructions. However, significant discrepancies exist:

**Overall Backend Completeness:**
- **V850:** ~95% complete ✅ (base 74 instructions, 6 system registers)
- **V850ES:** ~95% complete ✅ (same ISA as V850E1, limited to 6 base system registers)
- **V850E1:** ~95% complete ✅ (V850ES ISA + 12 additional system registers)
- **V850E2/V850E2M:** ~95% complete ✅ (all instructions implemented)
- **RH850G3M:** 0% implemented ❌ (16 critical instructions missing)
- **RH850G3MH:** 0% implemented ❌ (design variant of G3M)
- **Scheduling Models:** ~40% complete ⚠️ (missing dual-issue, branch prediction)

**Critical Issues:**
1. ❌ **RH850G3M/G3MH variants completely missing** (affects automotive/industrial)
2. ❌ **Atomic operations incomplete** (LDL.W/STC.W missing, only CAXI available)
3. ❌ **Cache control missing** (CACHE/PREF not implemented)
4. ⚠️ **Scheduling models incomplete** (dual-issue pipeline not modeled for V850E2+)
5. ⚠️ **Register banking not utilized** (FPU system registers inaccessible via bank selection)
6. ⚠️ **Cycle timings oversimplified** (variable-cycle instructions use fixed latencies)

---

## 1. CPU Variant Support

### ✅ Implemented Variants

**File:** `llvm/lib/Target/V850/V850.td` (Lines 65-76)

| Variant | Status | Features | Implementation Quality |
|---------|--------|----------|----------------------|
| v850 | ✅ Complete | Base ISA (74 instructions), 6 system registers (EIPC, EIPSW, FEPC, FEPSW, ECR, PSW) | 95% - Missing scheduling refinements |
| v850es | ✅ Complete | Same ISA as V850E1 (extended instruction set), 6 base system registers | 95% - Same as v850e1 for instructions |
| v850e1 | ✅ Complete | CALLT, PREPARE/DISPOSE, BSH/BSW/HSW, CMOV, 3-op MUL/DIV, SXB/SXH/ZXB/ZXH, LD.BU/HU, DBTRAP/DBRET + additional system registers (CTPC, CTPSW, DBPC, DBPSW, CTBP, DIR, BPC, ASID, breakpoint regs) | 95% - All instructions implemented |
| v850e2 | ✅ Complete | ADF/SBF, MAC/MACU, HSH, SCH0L/R/SCH1L/R, 3-op SAR/SHL/SHR, 48-bit JR/JARL/JMP | 95% - Scheduling needs dual-issue modeling |
| v850e2m | ✅ Complete | FPU, CAXI, SYSCALL, EIRET/FERET/FETRAP, SYNCE/SYNCM/SYNCP, RIE, DIVQ/DIVQU, disp23 load/store | 95% - FPU fully implemented |
| v850e2v3 | ✅ Complete | Same as v850e2m | 95% - Alias for v850e2m |
| v850e3 | ✅ Partial | V850E3 extensions | 85% - Basic support, needs verification |
| v850e3v5 | ✅ Partial | V850E3 variant | 85% - Basic support, needs verification |

### ❌ Missing Variants

| Variant | Status | Required Features | Priority |
|---------|--------|-------------------|----------|
| rh850g3m | ❌ Not Implemented | User/supervisor modes (PSW.UM), LDL.W/STC.W atomics, CLL, BINS, ROTL, LD.DW/ST.DW, LOOP, PUSHSP/POPSP, Bcond disp17, JARL [reg1] reg3, CACHE, PREF, SNOOZE, SYNCI, selID-based system registers, branch prediction | **High** |
| rh850g3mh | ❌ Not Implemented | RH850G3M + performance enhancements, simplified FPU exceptions (FPINT replaces FPP/FPI), advanced out-of-order execution | **High** |
| rh850g4m | ❌ Not Implemented | RH850G4 extensions | Medium |
| rh850g4mh | ❌ Not Implemented | RH850G4MH variant | Medium |

**Impact:** Automotive and industrial applications using RH850 MCUs cannot use LLVM.

---

## 2. Instruction Implementation Status

### 2.1 Complete Instruction Categories (V850-V850E2M)

**File:** `llvm/lib/Target/V850/V850InstrInfo.td`

| Category | Documented | Implemented | Coverage | Notes |
|----------|-----------|-------------|----------|-------|
| Basic Arithmetic | 11 | 11 | 100% ✅ | ADD, SUB, CMP, MOV, etc. |
| Saturated Arithmetic | 7 | 7 | 100% ✅ | SATADD, SATSUB variants |
| Logical | 8 | 8 | 100% ✅ | AND, OR, XOR, NOT, TST |
| Shift | 9 | 9 | 100% ✅ | SHR, SAR, SHL (2/3-operand forms) |
| Data Manipulation | 8 | 8 | 100% ✅ | BSH, BSW, HSH, HSW, SXB/H, ZXB/H |
| Bit Search | 4 | 4 | 100% ✅ | SCH0L/R, SCH1L/R |
| Bit Manipulation | 8 | 8 | 100% ✅ | SET1, CLR1, NOT1, TST1 (imm & reg) |
| Conditional | 6 | 6 | 100% ✅ | SETF, SASF, CMOV (imm & reg) |
| Multiply | 8 | 8 | 100% ✅ | MULH, MUL, MULU variants |
| MAC | 2 | 2 | 100% ✅ | MAC, MACU |
| **FPU (All)** | **71** | **71** | **100% ✅** | All arithmetic, conversion, rounding, comparison |

**Total Implemented (V850-V850E2M):** 192 instructions

### 2.2 Missing RH850G3M Instructions ❌

**File:** `llvm/lib/Target/V850/V850InstrInfo.td` - **NO RH850G3M INSTRUCTIONS**

| Instruction | Format | Category | Doc Reference | Priority | Impact |
|-------------|--------|----------|---------------|----------|--------|
| **LD.DW** disp23[reg1], reg3 | XIV (48-bit) | Load/Store | V850InstructionReference.md line 1535 | **High** | 64-bit loads required for RH850G3M |
| **ST.DW** reg3, disp23[reg1] | XIV (48-bit) | Load/Store | V850InstructionReference.md line 1535 | **High** | 64-bit stores required for RH850G3M |
| **LDL.W** [reg1], reg3 | IX | Atomic | V850CycleTimings.md line 255 | **Critical** | Load-linked for LL/SC atomic sequences |
| **STC.W** reg3, [reg1] | IX | Atomic | V850CycleTimings.md line 256 | **Critical** | Store-conditional for LL/SC atomic sequences |
| **CLL** | X | Atomic | Not in cycle doc | **Critical** | Clear load-link reservation |
| **BINS** reg1, pos, width, reg2 | XI | Data Manip | V850CycleTimings.md line 132 | Medium | Bitfield insert |
| **ROTL** imm5, reg2, reg3 | XI | Shift | V850CycleTimings.md line 117 | Medium | Rotate left by immediate |
| **ROTL** reg1, reg2, reg3 | XI | Shift | V850CycleTimings.md line 118 | Medium | Rotate left by register |
| **PUSHSP** rh-rt | X | Stack | Not in cycle doc | **High** | Push multiple registers to stack |
| **POPSP** rh-rt | X | Stack | Not in cycle doc | **High** | Pop multiple registers from stack |
| **LOOP** reg1, disp16 | VII | Branch | V850CycleTimings.md line 185 | Medium | Decrement and branch if not zero |
| **Bcond** disp17 | VII | Branch | V850CycleTimings.md line 177 | Medium | Extended 17-bit displacement branches |
| **JARL** [reg1], reg3 | XI | Branch | V850CycleTimings.md line 184 | Medium | Indirect jump and link |
| **CACHE** cacheop, [reg1] | IX | Cache | V850CycleTimings.md line 264 | Low | Cache control operations |
| **PREF** prefop, [reg1] | IX | Cache | V850CycleTimings.md line 265 | Low | Prefetch hint |
| **SNOOZE** | X | Special | Not in cycle doc | Low | Low-power snooze state |

**Total Missing RH850G3M:** 16 instructions (0% implemented)

**Critical Impact:** RH850G3M cannot be supported without these instructions. LDL.W/STC.W are essential for implementing C11/C++11 atomics.

### 2.3 Partial/Incomplete Instructions ⚠️

| Instruction | Status | Issue | File Location | Fix Required |
|------------|--------|-------|---------------|--------------|
| DIVQ/DIVQU | ⚠️ Implemented | Variable cycles (N+3 to N+5) simplified to fixed Latency=20 | V850Schedule.td:177-180 | Model variable latency based on operand width |
| PREPARE/DISPOSE | ⚠️ Implemented | Variable cycles (n+1/n+2) simplified to fixed Latency=4 | V850Schedule.td:201-202 | Model latency based on register list size |
| LDSR/STSR | ⚠️ Implemented | No selID operand for RH850G3M register banking | V850InstrInfo.td:696-713 | Add selID operand and bank validation |
| Bcond (all) | ⚠️ Implemented | Branch prediction not modeled (RH850G3M: 1-4 cycles) | V850Schedule.td:91-98 | Add RH850G3M model with prediction |
| LD.B/H/W | ⚠️ Implemented | Cycle timings differ by CPU variant, using simplified model | V850SchedV850E2M.td:30-45 | Separate timing per CPU variant |

---

## 3. System Register Implementation

### 3.1 Base System Registers (V850/V850ES/V850E1) ✅

**File:** `llvm/lib/Target/V850/V850RegisterInfo.td` (Lines 157-190)

| RegID | Name | Doc Status | Impl Status | Access | Issues |
|-------|------|------------|-------------|--------|--------|
| 0 | EIPC | ✅ | ✅ | R/W | None |
| 1 | EIPSW | ✅ | ✅ | R/W | None |
| 2 | FEPC | ✅ | ✅ | R/W | None |
| 3 | FEPSW | ✅ | ✅ | R/W | None |
| 4 | ECR | ✅ | ✅ | R | None |
| 5 | PSW | ✅ | ✅ | R/W | None |
| 6-15 | Reserved | ✅ | ✅ | - | None |

**Status:** ✅ Complete (6/6 base registers)

### 3.2 V850E1+ System Registers ⚠️

**File:** `llvm/lib/Target/V850/V850RegisterInfo.td` (Lines 191-220)

**Important Note - V850ES vs V850E1:**
- **V850ES** supports the same instruction set as V850E1 but has only the 6 base system registers (EIPC, EIPSW, FEPC, FEPSW, ECR, PSW)
- **V850E1** adds 12 additional system registers below for CALLT and debug functionality

| RegID | Name | Doc Status | Impl Status | Access | Priority | Issues |
|-------|------|------------|-------------|--------|----------|--------|
| 16 | CTPC | ✅ | ✅ | R/W | - | CALLT saved PC (V850E1 only) |
| 17 | CTPSW | ✅ | ✅ | R/W | - | CALLT saved PSW (V850E1 only) |
| 18 | DBPC | ✅ | ✅ | R/W | - | Debug saved PC (V850E1 only) |
| 19 | DBPSW | ✅ | ✅ | R/W | - | Debug saved PSW (V850E1 only) |
| 20 | CTBP | ✅ | ✅ | R/W | - | CALLT base pointer (V850E1 only) |
| 21 | DIR | ✅ | ❌ | R/W | Low | Debug interrupt register (V850E1 only) |
| 22 | BPC0 | ✅ | ❌ | R/W | Low | Breakpoint control (V850E1 only) |
| 23 | ASID | ✅ | ❌ | R/W | Low | Address space ID (V850E1 only) |
| 24-27 | BPAVn, BPAMn, BPDVn, BPDMn | ✅ | ❌ | R/W | Low | Breakpoint registers (V850E1 only) |

**Status:** ⚠️ Partial (5/12 V850E1 registers implemented, 42%)
**Priority:** Low (debug functionality, not required for code generation)
**V850ES Status:** ✅ Complete (uses only base 6 registers from Section 3.1)

### 3.3 V850E2M System Registers ⚠️

**File:** `llvm/lib/Target/V850/V850RegisterInfo.td` (Lines 220-245)

| RegID | Name | Doc Status | Impl Status | Access | Priority | Issues |
|-------|------|------------|-------------|--------|----------|--------|
| 6 | FPSR | ✅ | ✅ | R/W | - | FPU status |
| 7 | FPEPC | ✅ | ✅ | R/W | - | FPU exception PC |
| 8 | FPST | ✅ | ✅ | R/W | - | FPU sticky flags |
| 9 | FPCC | ✅ | ✅ | R/W | - | FPU condition code |
| 10 | FPCFG | ✅ | ✅ | R/W | - | FPU configuration |
| 11 | SCCFG/FPEC | ✅ | ✅ | R/W | - | System config / FPU exception cause |
| 12 | SCBP | ✅ | ✅ | R/W | - | System call base pointer |
| 13 | EIIC | ✅ | ❌ | R/W | Medium | Exception interrupt cause |
| 14 | FEIC | ✅ | ❌ | R/W | Medium | FE-level interrupt cause |
| 28 | EIWR | ✅ | ✅ | R/W | - | EI work register |
| 29 | FEWR | ✅ | ✅ | R/W | - | FE work register |
| 30 | DBWR | ✅ | ✅ | R/W | - | Debug work register |
| 31 | BSEL | ✅ | ✅ | R/W | - | Bank selection register |

**Status:** ⚠️ Mostly Complete (11/13 implemented, 85%)
**Priority:** Medium (EIIC, FEIC useful for exception handling)

### 3.4 V850E2M Register Banking ❌

**Status:** ❌ Not Implemented
**Documentation:** V850InstructionReference.md lines 726-1151

The V850E2M bank selection model using BSEL register is documented but not implemented in LDSR/STSR:

| Bank | BSEL Value | Group | Registers |
|------|------------|-------|-----------|
| CPU Main | 0x0000 | 0 | All general system registers |
| Exception Handler EI | 0x0010 | 0 | EIPC, EIPSW, EIIC, EIWR |
| Exception Handler FE | 0x0011 | 0 | FEPC, FEPSW, FEIC, FEWR |
| Processor Protection | 0x1000-0x1010 | 16 | MPM, MPRC, protection registers |
| FPU Status | 0x2000 | 32 | FPSR, FPEPC, FPST, FPCC, FPCFG, FPEC |
| User Banks | 0xFF00-0xFFFF | 255 | User-defined register banks |

**Current Issue:**
- BSEL register exists (RegID 31) but is not used by LDSR/STSR
- FPU system registers cannot be accessed via banking
- Processor protection registers cannot be accessed

**File Location:** `V850InstrInfo.td` lines 696-713
**Priority:** Low (primarily for OS/RTOS support)

### 3.5 RH850G3M System Registers (selID-based) ❌

**Status:** ❌ Not Implemented
**Documentation:** V850InstructionReference.md lines 763-804, RH850G3M software manual

RH850G3M uses a different system register access model: `LDSR reg2, regID, selID`

| selID | Group | Registers | Status | Priority |
|-------|-------|-----------|--------|----------|
| 0 | Basic | PSW, EIPC, EIPSW, FEPC, FEPSW, ECR, CTPC, CTPSW, FPU regs | ✅ Partial | High |
| 1 | Interrupt | ISPR, PMR, ICSR, INTCFG, RBASE, EBASE, INTBP, MCTL, PID | ❌ Not Impl | **Critical** |
| 2 | MPU | MPM, MPRC, MPLAn, MPUAn, MPATn | ❌ Not Impl | **Critical** |
| 5 | Cache | ICCTRL, ICERR, ICCFG, ICTAGL/H, ICDATL/H | ❌ Not Impl | Medium |
| 10 | FPU Alt | Alternative FPU register access | ❌ Not Impl | Low |

**Current Issue:**
- LDSR/STSR instructions have no selID operand
- RH850G3M system registers cannot be accessed
- Parser doesn't recognize 3-operand LDSR/STSR syntax

**Files Requiring Updates:**
- `V850InstrInfo.td` lines 696-713: Add selID operand
- `V850RegisterInfo.td`: Define selID-based registers
- `V850AsmParser.cpp`: Parse 3-operand LDSR/STSR

**Priority:** **Critical** for RH850G3M support

### 3.6 PSW Extensions for RH850G3M ❌

**Status:** ❌ Not Implemented
**Documentation:** V850InstructionReference.md lines 763-804

RH850G3M PSW has additional fields beyond V850E2M:

| Bits | Field | Purpose | V850E2M | RH850G3M | Impl Status |
|------|-------|---------|---------|----------|-------------|
| 30 | UM | User Mode | - | ✅ | ❌ |
| 19 | NPV | Non-Privileged | ✅ | ✅ | ✅ |
| 18 | CU2 | Coprocessor 2 Enable | - | ✅ | ❌ |
| 17 | CU1 | Coprocessor 1 Enable | - | ✅ | ❌ |
| 16 | CU0 | Coprocessor 0 Enable | - | ✅ | ❌ |
| 15 | EBV | Exception Base Vector | - | ✅ | ❌ |
| 14-12 | Reserved | - | - | - | - |
| 11-9 | Debug | Debug status field | - | ✅ | ❌ |

**Critical Impact:** User/Supervisor mode separation cannot be implemented without UM bit.

**Priority:** **Critical** for RH850G3M

---

## 4. Scheduling Model Status

### 4.1 Current Scheduling Models

**Files:**
- `llvm/lib/Target/V850/V850Schedule.td` (252 lines) - V850 base model
- `llvm/lib/Target/V850/V850SchedV850E2M.td` (212 lines) - V850E2M FPU model

### 4.2 Pipeline Characteristics vs Documentation

**Reference:** V850CycleTimings.md lines 7-16

| CPU Variant | Pipeline | Dual Issue | Branch Pred | Documented | Implemented | Status |
|-------------|----------|------------|-------------|------------|-------------|--------|
| V850 | 5-stage | No | No | V850CycleTimings.md | V850Schedule.td | ✅ Basic |
| V850ES/E1 | 5-stage | No | No | V850CycleTimings.md | V850Schedule.td | ✅ Basic |
| V850E2 | **7-stage** | **Yes (L/R)** | No | V850CycleTimings.md | V850Schedule.td | ❌ **Single-issue only** |
| V850E2M | **7-stage** | **Yes (L/R)** | No | V850CycleTimings.md | V850E2MModel | ❌ **Single-issue only** |
| RH850G3M | 7-stage | Yes | **Yes** | V850CycleTimings.md | - | ❌ **Not Implemented** |
| RH850G3MH | 7+ stage | Yes | **Yes** | V850CycleTimings.md | - | ❌ **Not Implemented** |

**Critical Issue:** V850E2/V850E2M have dual-issue superscalar pipelines (Lpipe/Rpipe) documented in V850CycleTimings.md lines 346-347, but the scheduling model treats them as single-issue.

### 4.3 Instruction Latency Discrepancies

**Reference:** V850CycleTimings.md, comparing against V850Schedule.td

#### Load Instructions

| Instruction | V850 Doc | V850E2M Doc | Implementation | Issue |
|-------------|----------|-------------|----------------|-------|
| LD.B/H/W | 1-1-2 | 1-1-3* | Latency=3 | ⚠️ Wrong for V850 (should be 2) |
| SLD.B/H/W | 1-1-2 | 1-1-3* | Latency=3 | ⚠️ Wrong for V850 (should be 2) |
| LD.BU/HU | 1-1-2* | 1-1-3* | Latency=3 | ⚠️ Wrong for V850ES/E1 (should be 2) |

**File:** V850Schedule.td lines 122-145

#### Multiply/Divide Instructions

| Instruction | V850 Doc | V850E1 Doc | V850E2 Doc | Implementation | Issue |
|-------------|----------|------------|------------|----------------|-------|
| MUL (3-op) | N/A | 1-4-5 | 1-1-3 | Latency=5 | ⚠️ Not variant-specific |
| DIV | N/A | 35-35-35 | 35-35-35 | Latency=36 | ⚠️ Close but not exact |
| DIVQ | N/A | N/A | N+5* | Latency=20 | ❌ **Oversimplified** |
| DIVQU | N/A | N/A | N+4* | Latency=20 | ❌ **Oversimplified** |

**Reference:** V850CycleTimings.md lines 150-168
**File:** V850Schedule.td lines 146-180

**DIVQ Issue:** Variable cycles (N = valid bits of dividend - valid bits of divisor, range 0-16) not modeled. Fixed Latency=20 is an average, not accurate for scheduling.

#### Branch Instructions (RH850G3M) ❌

| Instruction | RH850G3M Doc | Implementation | Issue |
|-------------|--------------|----------------|-------|
| Bcond disp9 (taken) | 1-4** | Not modeled | ❌ No RH850G3M model |
| Bcond disp9 (not taken) | 1-4** | Not modeled | ❌ No RH850G3M model |
| JR disp22/32 | 1-4** | Fixed 4 cycles | ❌ Branch prediction not modeled |

** 1 cycle if prediction matched, 4 if not matched

**Reference:** V850CycleTimings.md lines 174-186
**Impact:** RH850G3M code scheduling will be suboptimal without branch prediction modeling.

#### PREPARE/DISPOSE Instructions ⚠️

| Instruction | V850E1 Doc | V850E2M Doc | Implementation | Issue |
|-------------|------------|-------------|----------------|-------|
| PREPARE | n+1 | n+2 | Latency=4 | ⚠️ Doesn't scale with register count |
| DISPOSE | n+1 | n+2 | Latency=4 | ⚠️ Doesn't scale with register count |

n = number of registers in list12

**Reference:** V850CycleTimings.md lines 233-240
**File:** V850Schedule.td lines 201-202

#### FPU Instructions ⚠️

| Instruction | RH850G3M Imprecise | RH850G3M Precise | Implementation | Issue |
|-------------|-------------------|------------------|----------------|-------|
| ADDF.S | 1-1-4 | 7-7-7 | Latency=4 | ⚠️ No precise mode |
| DIVF.S | 14-14-17 | 20-20-20 | Latency=17 | ⚠️ No precise mode |
| DIVF.D | 30-30-33 | 36-36-36 | Latency=33 | ⚠️ No precise mode |

**Reference:** V850CycleTimings.md lines 280-322
**File:** V850SchedV850E2M.td lines 85-211

**Issue:** RH850G3M has both Imprecise (fast) and Precise (IEEE-compliant) FPU execution modes with very different latencies. Current implementation assumes imprecise mode only.

### 4.4 Resource Classes Not Modeled

**Reference:** V850CycleTimings.md lines 334-367

**V850E2/V850E2M Dual-Issue Pipeline (NOT MODELED):**

According to documentation, V850E2+ should have:
- **Lpipe:** Load/store, multiply, MAC
- **Rpipe:** ALU, shift, data manipulation, bit search
- **Both pipes:** Can execute many arithmetic/logical ops in parallel

**Current Implementation (V850Schedule.td):**
```tablegen
// Only single-issue resources defined:
def V850WriteALU : SchedWrite;
def V850WriteMem : SchedWrite;
def V850WriteBranch : SchedWrite;
def V850WriteMul : SchedWrite;
def V850WriteDiv : SchedWrite;
```

**Missing:**
- No Lpipe/Rpipe resource definitions
- No dual-issue itineraries
- No hazard detection for same-pipe conflicts

**Priority:** **High** - Impacts code generation quality for V850E2/V850E2M

### 4.5 Missing Scheduling Models

| CPU Variant | Required | Status | Priority |
|-------------|----------|--------|----------|
| RH850G3M | Yes | ❌ Not Implemented | **Critical** |
| RH850G3MH | Yes | ❌ Not Implemented | **Critical** |

**Files Needed:**
- `llvm/lib/Target/V850/V850SchedRH850G3M.td` (new)
- `llvm/lib/Target/V850/V850SchedRH850G3MH.td` (new)

---

## 5. Instruction Format Completeness

**File:** `llvm/lib/Target/V850/V850InstrFormats.td`

| Format | Size | Category | Doc | Impl | Status | Issues |
|--------|------|----------|-----|------|--------|--------|
| I | 16-bit | Reg-Reg | ✅ | ✅ | Complete | None |
| II | 16-bit | Imm-Reg | ✅ | ✅ | Complete | None |
| II-IMM6 | 16-bit | CALLT | ✅ | ✅ | Complete | CALLT variant |
| III | 16-bit | Conditional Branch | ✅ | ✅ | Complete | None |
| IV | 16-bit | Short Load/Store | ✅ | ✅ | Complete | None |
| IV-E1 | 16-bit | V850E1 SLD.BU/HU | ✅ | ✅ | Complete | V850E1 variant |
| V | 32-bit | Jump | ✅ | ✅ | Complete | None |
| VI | 32-bit | 3-op Immediate | ✅ | ✅ | Complete | None |
| VI-E2 | 48-bit | Extended Jump | ✅ | ✅ | Complete | V850E2 variant |
| VII | 32-bit | Load/Store | ✅ | ✅ | Complete | None |
| VIII | 32-bit | Bit Manipulation | ✅ | ✅ | Complete | None |
| IX | 32-bit | Extended 1-op | ✅ | ✅ | Complete | None |
| X | 32-bit | System/Special | ✅ | ✅ | Complete | None |
| XI | 32-bit | 3-op Extended | ✅ | ✅ | Complete | None |
| XI-IMM9 | 32-bit | 3-op w/ imm9 | ✅ | ✅ | Complete | 9-bit imm variant |
| XII | 32-bit | Bit Search | ✅ | ✅ | Complete | None |
| XIII | 32-bit | PREPARE/DISPOSE | ✅ | ✅ | Complete | None |
| **XIV** | 48-bit | 64-bit Load/Store | ✅ | ⚠️ | **Partial** | **Missing LD.DW/ST.DW for RH850G3M** |
| FI | 32-bit | FPU Base | ✅ | ✅ | Complete | FPU operations |

**Status:** 17/18 formats complete (94%)

**Format XIV Issue:** Defined for V850E2M disp23 loads (LD.BU/HU with 23-bit displacement), but RH850G3M also uses it for LD.DW/ST.DW (64-bit double-word loads/stores). These instructions are not implemented.

---

## 6. Opcode Encoding Verification

### 6.1 Base Instruction Formats ✅

Comparing V850InstructionReference.md opcode tables against V850InstrInfo.td:

#### Format I (16-bit reg-reg) - Lines 1382-1409

| Bits 10:7 | Bits 6:5=00 | Bits 6:5=01 | Bits 6:5=10 | Bits 6:5=11 | Status |
|-----------|-------------|-------------|-------------|-------------|--------|
| 0000 | MOV/NOP | NOT | DIVH | JMP | ✅ Verified |
| 0001 | SATSUBR/ZXB | SATSUB/SXB | SATADD/ZXH | MULH/SXH | ✅ Verified |
| 0010 | OR | XOR | AND | TST | ✅ Verified |
| 0011 | SUBR | SUB | ADD | CMP | ✅ Verified |

**Status:** ✅ All Format I encodings verified

#### Format II (16-bit imm-reg) - Lines 1411-1416

| Bits 10:7 | Bits 6:5=00 | Bits 6:5=01 | Bits 6:5=10 | Bits 6:5=11 | Status |
|-----------|-------------|-------------|-------------|-------------|--------|
| 0100 | MOV imm5/CALLT | SATADD imm5 | ADD imm5 | CMP imm5 | ✅ Verified |
| 0101 | SHR imm5 | SAR imm5 | SHL imm5 | MULH imm5 | ✅ Verified |

**Status:** ✅ All Format II encodings verified

#### Format III (Conditional Branch) - Lines 1430-1447

All 16 condition codes (V, C, Z, NH, S, T, LT, LE, NV, NC, NZ, H, NS, SA, GE, GT) verified.

**Status:** ✅ Complete

#### Format IV (Short Load/Store) - Lines 1418-1428

| Opcode | Bit 0=0 | Bit 0=1 | Status |
|--------|---------|---------|--------|
| 0110 | - | SLD.B | ✅ Verified |
| 0111 | - | SST.B | ✅ Verified |
| 1000 | - | SLD.H | ✅ Verified |
| 1001 | - | SST.H | ✅ Verified |
| 1010 | SLD.W | SST.W | ✅ Verified |

**Status:** ✅ Complete

#### Format VII (Load/Store) - Lines 1490-1499

| Bits 6:5 | Bit 16=0 | Bit 16=1 | Status |
|----------|----------|----------|--------|
| 00 | LD.B | - | ✅ Verified |
| 01 | LD.H | LD.W | ✅ Verified |
| 10 | ST.B | - | ✅ Verified |
| 11 | ST.H | ST.W | ✅ Verified |

**Status:** ✅ Complete

#### Format XIV (48-bit Load/Store) - Lines 1527-1536

| Opcode | Sub-op | Bit 16 | Instruction | Arch | Status |
|--------|--------|--------|-------------|------|--------|
| 111101 | 00100 | 1 | LD.BU disp23 | V850E2M | ✅ Implemented |
| 111101 | 00101 | 1 | LD.BU disp23 | V850E2M | ✅ Implemented |
| 111101 | 00111 | 1 | LD.HU disp23 | V850E2M | ✅ Implemented |
| 111101 | ????? | ? | LD.DW disp23 | RH850G3M | ❌ **NOT IMPLEMENTED** |
| 111101 | ????? | ? | ST.DW disp23 | RH850G3M | ❌ **NOT IMPLEMENTED** |

**Status:** ⚠️ Partial - Missing RH850G3M double-word loads/stores

### 6.2 Extended Instructions (opcode=111111) ⚠️

**Reference:** V850InstructionReference.md lines 1544-1587

#### Format IX - System and Bit Operations

| Bits 26:23 | Bits 22:21=00 | Bits 22:21=01 | Bits 22:21=10 | Bits 22:21=11 | Status |
|------------|---------------|---------------|---------------|---------------|--------|
| 0000 | SETF | LDSR | STSR | - | ✅ Implemented |
| 0001 | SHR reg | SAR reg | SHL reg | Bit ops | ✅ Implemented |
| 0010 | TRAP | HALT | RETI/CTRET/DBRET | DI/EI | ✅ Implemented |
| 0011 | - | - | PREPARE | DISPOSE | ✅ Implemented |
| 0100 | SASF | MUL family | DIV family | DIVH_3 | ✅ Implemented |
| 0101 | DIVHU family | - | DIV family | DIVQ (E2M) | ✅ Implemented |
| 0110 | CMOV imm | BSW/BSH/HSW/SCH | CMOV reg | - | ✅ Implemented |
| 0111 | SBF (E2) | ADF (E2) | MAC (E2) | MACU (E2) | ✅ Implemented |
| 1000 | FPU Instructions (E2M) | ✅ Implemented |

**Status:** ✅ All defined extended instructions implemented for V850-V850E2M

**Missing for RH850G3M:** No sub-opcode assignments for LDL.W, STC.W, CLL, CACHE, PREF, SYNCI, ROTL, BINS, etc.

### 6.3 FPU Instructions (bits[10:5]=111111) ✅

**Reference:** V850InstructionReference.md lines 1595-1698

All 71 FPU instructions verified with correct sub-opcode encodings (bits[26:21]):
- Arithmetic: ADDF, SUBF, MULF, DIVF (010000-010011)
- Unary: ABSF, NEGF, SQRTF, RECIPF, RSQRTF (001000-001001)
- Conversion: CVTF.* (18 variants, 010100)
- Rounding: CEILF.*, FLOORF.*, TRNCF.* (24 variants, 010100)
- Comparison: CMPF, CMOVF, TRFSR (011000, 010000)
- Fused MA: MADDF.S, MSUBF.S, NMADDF.S, NMSUBF.S (101W00-101W11)

**Status:** ✅ All FPU opcodes verified and implemented

---

## 7. Feature Flag and Predicate Analysis

### 7.1 Current Feature Flags

**File:** `llvm/lib/Target/V850/V850Subtarget.h` (Lines 35-40)

```cpp
bool HasV850E1 = false;    // Line 36
bool HasV850E2 = false;    // Line 37
bool HasV850E2M = false;   // Line 38
bool HasV850FPU = false;   // Line 39
bool HasV850E3 = false;    // Line 40
```

**File:** `llvm/lib/Target/V850/V850InstrInfo.td` (Lines 164-172)

```tablegen
def HasV850E1  : Predicate<"Subtarget->hasV850E1()">;
def HasV850E2  : Predicate<"Subtarget->hasV850E2()">;
def HasV850E2M : Predicate<"Subtarget->hasV850E2M()">;
def HasV850FPU : Predicate<"Subtarget->hasV850FPU()">;
def HasV850E3  : Predicate<"Subtarget->hasV850E3()">;
```

**Status:** ✅ Complete for V850-V850E3

### 7.2 Missing Feature Flags for RH850G3M ❌

**Required Additions:**

```cpp
// V850Subtarget.h additions needed:
bool HasRH850G3M = false;
bool HasRH850G3MH = false;
bool HasRH850Atomics = false;    // LDL.W/STC.W/CLL
bool HasRH850Cache = false;       // CACHE/PREF
bool HasRH850UserMode = false;    // PSW.UM support
bool HasBranchPrediction = false; // For scheduling
```

```tablegen
// V850InstrInfo.td additions needed:
def HasRH850G3M  : Predicate<"Subtarget->hasRH850G3M()">;
def HasRH850G3MH : Predicate<"Subtarget->hasRH850G3MH()">;
def HasRH850Atomics : Predicate<"Subtarget->hasRH850Atomics()">;
def HasRH850Cache : Predicate<"Subtarget->hasRH850Cache()">;
```

**Priority:** **Critical** for RH850G3M implementation

### 7.3 Feature Implication Analysis

**Required Feature Dependencies:**

```
V850 (base - 74 instructions, 6 system registers)
  └── V850ES (same ISA as V850E1, 6 system registers only)
      └── V850E1 (same ISA as V850ES + additional system registers: CTPC, CTPSW, DBPC, DBPSW, CTBP, DIR, BPC, ASID, breakpoint regs)
          └── V850E2 (implies V850E1)
              └── V850E2M (implies V850E2)
                  ├── V850E3 (implies V850E2M + FPU)
                  └── RH850G3M (implies V850E2M + FPU + Atomics + Cache)
                      └── RH850G3MH (implies RH850G3M + Branch Prediction)
```

**Key Distinction - V850ES vs V850E1:**
- **V850ES:** Extended instruction set (same as V850E1) but limited to 6 base system registers
- **V850E1:** Same instruction set as V850ES + full set of system registers (12 additional registers for debug/CALLT)

**Status:** ✅ V850-V850E3 implications correct
**Status:** ❌ RH850G3M/G3MH not in chain

---

## 8. Implementation Action Items

### Priority 1 (Critical) - RH850G3M Foundation

**Estimated Effort:** 3-4 weeks

#### 1.1 Add RH850G3M CPU Variants and Features

**Files:**
- `llvm/lib/Target/V850/V850.td`
- `llvm/lib/Target/V850/V850Subtarget.h`
- `llvm/lib/Target/V850/V850Subtarget.cpp`

**Tasks:**
1. Add FeatureRH850G3M, FeatureRH850G3MH, FeatureRH850Atomics, FeatureRH850Cache
2. Add processor definitions: `rh850g3m`, `rh850g3mh`
3. Define feature implications (RH850G3M implies V850E2M + FPU)
4. Add predicates to V850InstrInfo.td

**Acceptance Criteria:**
- `clang -target v850-unknown-elf -mcpu=rh850g3m` compiles without error
- Feature flags properly set in subtarget

#### 1.2 Implement selID-based System Register Access

**Files:**
- `llvm/lib/Target/V850/V850RegisterInfo.td`
- `llvm/lib/Target/V850/V850InstrInfo.td`
- `llvm/lib/Target/V850/V850AsmParser.cpp`

**Tasks:**
1. Add selID operand to LDSR/STSR instruction definitions
2. Define RH850G3M system register groups (selID 0-10)
3. Update assembly parser to accept `LDSR reg2, regID, selID` syntax
4. Add register definitions for RH850G3M (ISPR, PMR, ICSR, INTCFG, RBASE, EBASE, MPM, MPRC, etc.)

**Acceptance Criteria:**
- `ldsr r10, 5, 1` assembles correctly (access PSW via selID 1)
- All RH850G3M system registers defined and accessible

#### 1.3 Implement PSW Extensions for User/Supervisor Mode

**Files:**
- `llvm/lib/Target/V850/V850RegisterInfo.td`
- `llvm/lib/Target/V850/V850ISelLowering.cpp`

**Tasks:**
1. Add UM (bit 30), CU0-CU2 (bits 18-16), EBV (bit 15), Debug (bits 11-9) to PSW
2. Update PSW read/write handling for RH850G3M
3. Implement privilege checking for supervisor-only instructions (if needed)

**Acceptance Criteria:**
- PSW bit layout matches RH850G3M specification
- UM bit can be set/cleared via LDSR/STSR

#### 1.4 Implement RH850G3M Atomic Instructions

**Files:**
- `llvm/lib/Target/V850/V850InstrInfo.td`
- `llvm/lib/Target/V850/V850ISelLowering.cpp`

**Tasks:**
1. Add LDL.W (load linked word) instruction - Format IX
2. Add STC.W (store conditional word) instruction - Format IX
3. Add CLL (clear load link) instruction - Format X
4. Implement atomic lowering (C11/C++11 atomic operations → LDL.W/STC.W sequences)
5. Add test cases for atomic operations

**Acceptance Criteria:**
- LDL.W/STC.W assemble and encode correctly
- Atomic compare-exchange lowers to LDL.W/STC.W sequence
- C11 `_Atomic` operations compile correctly

#### 1.5 Implement RH850G3M Load/Store Instructions

**Files:**
- `llvm/lib/Target/V850/V850InstrInfo.td`

**Tasks:**
1. Add LD.DW (load double-word, 64-bit) - Format XIV
2. Add ST.DW (store double-word, 64-bit) - Format XIV
3. Handle register pair constraints (even-numbered register requirement)
4. Add instruction selection patterns for 64-bit loads/stores

**Acceptance Criteria:**
- `ld.dw 0x100[r10], r2` assembles correctly (r2 must be even-numbered)
- 64-bit loads/stores selected correctly in codegen

### Priority 2 (High) - RH850G3M Remaining Instructions

**Estimated Effort:** 2-3 weeks

#### 2.1 Data Manipulation Instructions

**Files:** `llvm/lib/Target/V850/V850InstrInfo.td`

**Tasks:**
1. Add BINS (bitfield insert) - Format XI
2. Add ROTL imm5, reg2, reg3 (rotate left by immediate) - Format XI
3. Add ROTL reg1, reg2, reg3 (rotate left by register) - Format XI
4. Add instruction selection patterns

**Acceptance Criteria:**
- All 3 instructions assemble correctly
- ROTL selected for appropriate IR patterns

#### 2.2 Stack Management Instructions

**Files:** `llvm/lib/Target/V850/V850InstrInfo.td`

**Tasks:**
1. Add PUSHSP rh-rt (push multiple registers) - Format X
2. Add POPSP rh-rt (pop multiple registers) - Format X
3. Add instruction selection patterns for function prologue/epilogue

**Acceptance Criteria:**
- PUSHSP/POPSP assemble correctly
- Prologue/epilogue can use PUSHSP/POPSP for efficient register saves

#### 2.3 Branch and Loop Instructions

**Files:** `llvm/lib/Target/V850/V850InstrInfo.td`

**Tasks:**
1. Add Bcond disp17 (extended conditional branch) - Format VII
2. Add JARL [reg1], reg3 (indirect jump and link) - Format XI
3. Add LOOP reg1, disp16 (decrement and branch) - Format VII
4. Add branch selection patterns

**Acceptance Criteria:**
- All branch variants assemble correctly
- Long-distance branches use disp17 variant when needed

#### 2.4 Cache and Synchronization Instructions

**Files:** `llvm/lib/Target/V850/V850InstrInfo.td`

**Tasks:**
1. Add CACHE cacheop, [reg1] - Format IX
2. Add PREF prefop, [reg1] - Format IX
3. Add SYNCI - Format X
4. Add SNOOZE - Format X

**Acceptance Criteria:**
- All instructions assemble correctly
- CACHE/PREF can be used in inline assembly

### Priority 3 (Medium) - Scheduling Model Improvements

**Estimated Effort:** 2-3 weeks

#### 3.1 V850E2/V850E2M Dual-Issue Pipeline Model

**Files:**
- `llvm/lib/Target/V850/V850SchedV850E2M.td`
- `llvm/lib/Target/V850/V850Schedule.td`

**Tasks:**
1. Define Lpipe and Rpipe resources
2. Update instruction definitions with pipe assignments:
   - Lpipe: Load/store, multiply, MAC
   - Rpipe: ALU, shift, data manipulation, bit search
   - Both: Many arithmetic/logical ops
3. Define dual-issue constraints (same pipe cannot dual-issue)
4. Add itineraries for parallel execution

**Reference:** V850CycleTimings.md lines 334-367

**Acceptance Criteria:**
- Instructions correctly assigned to pipes
- Dual-issue scheduling observed in generated code
- Performance improvement measurable on V850E2/V850E2M

#### 3.2 Variable-Latency Instruction Modeling

**Files:**
- `llvm/lib/Target/V850/V850Schedule.td`
- `llvm/lib/Target/V850/V850SchedV850E2M.td`

**Tasks:**
1. Model DIVQ/DIVQU variable latency (N+3 to N+5 based on operand width)
2. Model PREPARE/DISPOSE variable latency (n+1 to n+2 based on register count)
3. Model load latency differences by CPU variant (V850: 1-1-2, V850E2M: 1-1-3)

**Reference:** V850CycleTimings.md lines 166-168, 233-240

**Acceptance Criteria:**
- DIVQ latency varies based on operand analysis
- PREPARE/DISPOSE latency accounts for register list size

#### 3.3 RH850G3M/G3MH Scheduling Models

**Files:**
- `llvm/lib/Target/V850/V850SchedRH850G3M.td` (new)
- `llvm/lib/Target/V850/V850SchedRH850G3MH.td` (new)
- `llvm/lib/Target/V850/V850.td`

**Tasks:**
1. Create RH850G3M scheduling model with branch prediction
2. Model prediction-dependent branch latencies (1-4 cycles)
3. Create RH850G3MH scheduling model with advanced out-of-order features
4. Update instruction latencies per V850CycleTimings.md:
   - Improved divide latencies (19 cycles vs 35-36)
   - Dual-mode FPU (imprecise vs precise)
   - Cache instruction timings

**Reference:** V850CycleTimings.md lines 161-168, 174-189, 280-331

**Acceptance Criteria:**
- RH850G3M processor model defined
- Branch prediction effects observable in scheduling
- FPU imprecise/precise modes modeled

#### 3.4 FPU Imprecise/Precise Mode Modeling

**Files:** `llvm/lib/Target/V850/V850SchedV850E2M.td`

**Tasks:**
1. Add FPU mode selection (imprecise vs precise)
2. Update FPU instruction latencies per mode:
   - Imprecise: ADDF.S 1-1-4, DIVF.S 14-14-17
   - Precise: ADDF.S 7-7-7, DIVF.S 20-20-20
3. Provide compiler option to select FPU mode

**Reference:** V850CycleTimings.md lines 280-331

**Acceptance Criteria:**
- `-mfpu-mode=imprecise` and `-mfpu-mode=precise` flags work
- Scheduling uses correct latencies per mode

### Priority 4 (Low) - Debug and Enhancement

**Estimated Effort:** 1-2 weeks

#### 4.1 Complete V850E1 Debug Registers

**Files:** `llvm/lib/Target/V850/V850RegisterInfo.td`

**Tasks:**
1. Add DIR (Debug Interrupt Register) - RegID 21
2. Add BPC0 (Breakpoint Control) - RegID 22
3. Add ASID (Address Space ID) - RegID 23
4. Add BPAV0-3, BPAM0-3, BPDV0-3, BPDM0-3 (Breakpoint Address/Data/Mask registers)

**Acceptance Criteria:**
- All debug registers accessible via LDSR/STSR
- Debug register values preserved across context switches

#### 4.2 Complete V850E2M Exception Registers

**Files:** `llvm/lib/Target/V850/V850RegisterInfo.td`

**Tasks:**
1. Add EIIC (EI-level Interrupt Cause) - RegID 13
2. Add FEIC (FE-level Exception Cause) - RegID 14

**Acceptance Criteria:**
- EIIC/FEIC accessible via LDSR/STSR
- Exception handlers can read cause codes

#### 4.3 Implement V850E2M Register Banking

**Files:**
- `llvm/lib/Target/V850/V850InstrInfo.td`
- `llvm/lib/Target/V850/V850ISelLowering.cpp`

**Tasks:**
1. Use BSEL register to select register banks
2. Implement bank switching for FPU registers (BSEL=0x2000)
3. Implement bank switching for protection registers (BSEL=0x1000-0x1010)
4. Update LDSR/STSR to validate bank selection

**Acceptance Criteria:**
- FPU system registers accessible via BSEL=0x2000
- Protection registers accessible via BSEL=0x1000

---

## 9. Testing Requirements

### 9.1 RH850G3M Instruction Tests

**Directory:** `llvm/test/CodeGen/V850/`

Required test files:
1. `rh850g3m-atomics.ll` - LDL.W/STC.W/CLL atomic operations
2. `rh850g3m-double-word.ll` - LD.DW/ST.DW 64-bit loads/stores
3. `rh850g3m-branches.ll` - Bcond disp17, JARL [reg1], LOOP
4. `rh850g3m-data-manip.ll` - BINS, ROTL variants
5. `rh850g3m-stack.ll` - PUSHSP/POPSP
6. `rh850g3m-cache.ll` - CACHE/PREF/SYNCI
7. `rh850g3m-sysregs.ll` - selID-based LDSR/STSR

### 9.2 Assembly Syntax Tests

**Directory:** `llvm/test/MC/V850/`

Required test files:
1. `rh850g3m-atomics.s` - Atomic instruction encoding
2. `rh850g3m-sysreg-selid.s` - 3-operand LDSR/STSR syntax
3. `rh850g3m-branches.s` - Extended branch encoding
4. `rh850g3m-double-word.s` - LD.DW/ST.DW encoding

### 9.3 Scheduling Tests

**Directory:** `llvm/test/CodeGen/V850/`

Required test files:
1. `sched-v850e2-dual-issue.ll` - Dual-issue pipeline verification
2. `sched-rh850g3m-branch-prediction.ll` - Branch prediction effects
3. `sched-divq-variable.ll` - Variable DIVQ latency
4. `sched-prepare-dispose-variable.ll` - Variable PREPARE/DISPOSE latency

### 9.4 C/C++ Integration Tests

**Directory:** `clang/test/CodeGen/`

Required test files:
1. `v850-rh850g3m-atomic.c` - C11 atomic operations
2. `v850-rh850g3m-fpu-modes.c` - FPU imprecise/precise mode selection
3. `v850-rh850g3m-cache-hints.c` - __builtin_prefetch lowering

---

## 10. Documentation Updates Required

### 10.1 V850InstructionReference.md

**Status:** ✅ Mostly Complete (updated in commit 96e8a965174e)

Remaining updates:
1. ✅ Complete opcode summary for all instructions (DONE)
2. ✅ Add FPU instruction opcode tables (DONE)
3. ⚠️ Add RH850G3M instruction descriptions when implemented
4. ⚠️ Update system register table with selID-based access model

### 10.2 V850CycleTimings.md

**Status:** ✅ Complete

No updates needed. This document accurately reflects all CPU variant timing specifications.

### 10.3 LLVM User Documentation

**Files to Create/Update:**
1. `llvm/docs/V850TargetGuide.rst` (new) - V850 backend user guide
2. `clang/docs/V850Options.rst` (new) - Clang V850-specific options

Content needed:
- Supported CPU variants (v850, v850e1, v850e2, v850e2m, rh850g3m, rh850g3mh)
- Feature flags (-mv850e2m, -mfpu, -mrh850g3m)
- FPU mode selection (-mfpu-mode=imprecise/precise)
- Atomic operation support
- Inline assembly constraints
- System register access

---

## 11. Estimated Implementation Timeline

### Phase 1: RH850G3M Foundation (4 weeks)
- Week 1-2: CPU variants, feature flags, predicates, selID-based system registers
- Week 3: PSW extensions, atomic instructions (LDL.W/STC.W/CLL)
- Week 4: LD.DW/ST.DW, testing

### Phase 2: RH850G3M Remaining Instructions (3 weeks)
- Week 5: Data manipulation (BINS, ROTL), stack (PUSHSP/POPSP)
- Week 6: Branches (Bcond disp17, JARL [reg1], LOOP)
- Week 7: Cache/sync (CACHE, PREF, SYNCI, SNOOZE), testing

### Phase 3: Scheduling Model Improvements (3 weeks)
- Week 8: V850E2/V850E2M dual-issue pipeline modeling
- Week 9: Variable-latency instructions, RH850G3M scheduling model
- Week 10: RH850G3MH scheduling model, FPU imprecise/precise modes

### Phase 4: Debug and Polish (2 weeks)
- Week 11: Debug registers, V850E2M register banking
- Week 12: Documentation, final testing, code review

**Total Estimated Effort:** 12 weeks (3 months) for complete RH850G3M/G3MH support

---

## 12. Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| selID-based register access breaks existing code | Low | High | Maintain backward compatibility with 2-operand LDSR/STSR |
| RH850G3M opcode conflicts with existing instructions | Medium | High | Thorough opcode map verification before implementation |
| Dual-issue scheduling complexity | High | Medium | Implement incrementally, validate with benchmarks |
| Variable-latency modeling performance overhead | Medium | Low | Use heuristics for DIVQ, optimize for common cases |
| Insufficient RH850G3M documentation | Medium | High | Request additional documentation from Renesas |
| Testing coverage gaps | High | Medium | Comprehensive test plan, automated validation |

---

## Summary

**Current State:**
- **V850:** 95% complete, production-ready (base 74 instructions, 6 system registers)
- **V850ES:** 95% complete, production-ready (same ISA as V850E1, 6 system registers only)
- **V850E1:** 95% complete, production-ready (V850ES ISA + 12 additional system registers)
- **V850E2/V850E2M:** 95% complete, production-ready (all instructions and features)
- **RH850G3M/G3MH:** 0% complete, requires significant work

**Key Architecture Distinction:**
V850ES and V850E1 share the same instruction set architecture (ISA). The difference is:
- V850ES: Extended ISA with only 6 base system registers
- V850E1: Same extended ISA + 12 additional system registers for CALLT and debug features

**Critical Path:**
1. RH850G3M CPU variants and feature flags
2. selID-based system register access
3. Atomic instructions (LDL.W/STC.W/CLL)
4. LD.DW/ST.DW 64-bit loads/stores
5. Dual-issue scheduling model (V850E2+)
6. RH850G3M scheduling model with branch prediction

**Recommended Approach:**
- Prioritize RH850G3M foundation (Phase 1) for immediate usability
- Defer scheduling optimizations (Phase 3) until basic functionality complete
- Implement incrementally with comprehensive testing at each stage
- Maintain backward compatibility with existing V850-V850E2M code
