# V850 Implementation Verification Plan

This document compares the current V850 LLVM backend implementation against the updated V850InstructionReference.md and V850CycleTimings.md documentation and identifies all discrepancies that need to be addressed.

**Date:** 2026-01-11 (Updated - Scheduling models complete)
**Documentation References:**
- docs/V850InstructionReference.md (commit 96e8a965174e)
- docs/V850CycleTimings.md (comprehensive cycle timing specifications)
**Implementation Base:** llvm/lib/Target/V850/

---

## Executive Summary

The V850 backend has comprehensive support for V850, V850ES, V850E1, V850E2, and V850E2M CPU variants with 322 instruction definitions and 71 FPU instructions. However, significant discrepancies exist:

**Overall Backend Completeness:**
- **V850:** 100% complete ✅ (base 74 instructions, 6 system registers)
- **V850ES:** 100% complete ✅ (extended ISA same as V850E1, 6 base system registers)
- **V850E1:** 100% complete ✅ (extended ISA + 18 system registers including debug/CALLT)
- **V850E2/V850E2M:** 100% complete ✅ (all instructions and 32 system registers implemented)
- **RH850G3M:** 0% implemented ❌ (16 critical instructions missing)
- **RH850G3MH:** 0% implemented ❌ (design variant of G3M)
- **Scheduling Models:** 85% complete ✅ (V850/V850E1/V850E2/V850E2M models complete, missing RH850G3M)

**Critical Issues:**
1. ❌ **RH850G3M/G3MH variants completely missing** (affects automotive/industrial)
2. ❌ **Atomic operations incomplete** (LDL.W/STC.W missing, only CAXI available)
3. ❌ **Cache control missing** (CACHE/PREF not implemented)
4. ✅ **Scheduling models complete for V850-V850E2M** (dual-issue pipeline now modeled)
5. ⚠️ **Register banking not utilized** (FPU system registers inaccessible via bank selection)
6. ⚠️ **Variable-cycle instructions simplified** (DIVQ/PREPARE/DISPOSE use fixed latencies)

---

## 1. CPU Variant Support

### ✅ Implemented Variants

**File:** `llvm/lib/Target/V850/V850.td` (Lines 65-76)

| Variant | Status | Features | Implementation Quality |
|---------|--------|----------|----------------------|
| v850 | ✅ Complete | Base ISA (74 instructions), 6 system registers (EIPC, EIPSW, FEPC, FEPSW, ECR, PSW) | 100% - All base features complete |
| v850es | ✅ Complete | Extended ISA (same as V850E1: CALLT, PREPARE/DISPOSE, BSH/BSW/HSW, CMOV, 3-op MUL/DIV, SXB/SXH/ZXB/ZXH, LD.BU/HU, DBTRAP/DBRET), 6 base system registers only | 100% - Instruction set complete, system registers limited by hardware |
| v850e1 | ✅ Complete | Extended ISA (same as V850ES) + 18 system registers (6 base + CTPC, CTPSW, CTBP, DBPC, DBPSW, DIR, BPC, ASID, BPAV, BPAM, BPDV, BPDM) | 100% - All instructions and system registers implemented |
| v850e2 | ✅ Complete | V850E1 + ADF/SBF, MAC/MACU, HSH, SCH0L/R/SCH1L/R, 3-op SAR/SHL/SHR, 48-bit JR/JARL/JMP | 100% - All instructions implemented, scheduling needs dual-issue modeling |
| v850e2m | ✅ Complete | V850E2 + FPU (71 instructions), CAXI, SYSCALL, EIRET/FERET/FETRAP, SYNCE/SYNCM/SYNCP, RIE, DIVQ/DIVQU, disp23 load/store, 32 system registers | 100% - All instructions and FPU fully implemented |
| v850e2v3 | ✅ Complete | Alias for v850e2m | 100% - Same as v850e2m |
| v850e3 | ✅ Partial | V850E3 extensions | 85% - Basic support, needs verification |
| v850e3v5 | ✅ Partial | V850E3 variant | 85% - Basic support, needs verification |

**Important Note: V850ES vs V850E1 Distinction**

V850ES and V850E1 share the same instruction set architecture (ISA) but differ in available system registers:

- **V850ES:** Extended instruction set + 6 base system registers
  - System registers: EIPC, EIPSW, FEPC, FEPSW, ECR, PSW
  - No CALLT system registers (CTPC, CTPSW, CTBP)
  - No debug system registers (DBPC, DBPSW, DIR, BPC, ASID, BPAV, BPAM, BPDV, BPDM)

- **V850E1:** Extended instruction set + 18 system registers
  - All 6 base system registers (same as V850ES)
  - CALLT system registers: CTPC, CTPSW, CTBP
  - Debug system registers: DBPC, DBPSW, DIR, BPC, ASID, BPAV, BPAM, BPDV, BPDM

The LLVM compiler uses `FeatureV850E1` for both variants because they share the same instruction set. System register availability is a hardware constraint, not enforced at compile time. Both variants can compile the same code; the difference is which system registers the hardware supports.

### ❌ Missing Variants

| Variant | Status | Required Features | Priority |
|---------|--------|-------------------|----------|
| rh850g3m | ❌ Not Implemented | User/supervisor modes (PSW.UM), LDL.W/STC.W atomics, CLL, BINS, ROTL, LD.DW/ST.DW, LOOP, PUSHSP/POPSP, Bcond disp17, JARL [reg1] reg3, CACHE, PREF, SNOOZE, SYNCI, selID-based system registers, branch prediction | **High** |
| rh850g3mh | ❌ Not Implemented | RH850G3M + performance enhancements, simplified FPU exceptions (FPINT replaces FPP/FPI), advanced out-of-order execution | **High** |
| rh850g4mh | ⚠️ Documented | RH850G3MH + LDM.MP/STM.MP for MPU entry load/store, PID[31:24]=06H | Medium |
| rh850g4mh2 | ⚠️ Documented | RH850G4MH + virtualization support (Guest/Host modes, HVTRAP, LDM.GSR/STM.GSR, EIRET/FERET enhancements), PID[31:24]=07H | Medium |

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

# V850 Complete Register Reference

This section documents all registers (program, FPU, and system) for all V850 CPU variants.

---

## 3. Register Implementation

### 3.1 Program Registers (General Purpose Registers)

**File:** `llvm/lib/Target/V850/V850RegisterInfo.td` (Lines 50-82)

**Variants:** All V850 variants (V850, V850ES, V850E1, V850E2, V850E2M, V850E3, RH850G3M, RH850G3MH)

All V850 CPU variants share the same 32 general-purpose registers plus PC.

#### 3.1.1 General-Purpose Registers (r0-r31)

| Register | ABI Name | Size | Usage | Special Constraints | Implicit Use |
|----------|----------|------|-------|-------------------|--------------|
| **r0** | zero | 32-bit | Zero register | Always holds 0, read-only | Operations using 0, offset 0 addressing |
| **r1** | - | 32-bit | Assembler-reserved | Save before use, restore after | Address generation by assembler |
| **r2** | - | 32-bit | Variable / RTOS | May be used by RTOS, check before use | Potentially used by real-time OS |
| **r3** | SP | 32-bit | Stack pointer | Save before use, restore after | PREPARE, DISPOSE (V850E1+); PUSHSP, POPSP (RH850G3M+) |
| **r4** | GP | 32-bit | Global pointer | Save before use, restore after | Global variable access in data area |
| **r5** | TP | 32-bit | Text pointer | Save before use, restore after | Points to start of text area (code) |
| **r6-r29** | - | 32-bit | General purpose | None | No implicit use |
| **r30** | EP | 32-bit | Element pointer | None | Base pointer for SLD/SST instructions |
| **r31** | LP | 32-bit | Link pointer | Save before use, restore after | Function calls by compiler |

**Reset Values:**
- **r0:** Always 0 (not affected by reset)
- **r1-r31:** Undefined after reset
- Registers must be initialized by software before use

**Calling Convention Notes:**
- Caller-saved: r6-r19 (volatile, not preserved across function calls)
- Callee-saved: r20-r29 (must be preserved by called function)
- Special registers (r1, r3-r5, r30-r31) used by compiler/assembler
- See compiler documentation for ABI details

**CPU Variant Differences:**
- **V850/V850ES/V850E1/V850E2/V850E2M:** r3 used by PREPARE/DISPOSE instructions
- **RH850G3M/RH850G3MH:** r3 also used by PUSHSP/POPSP instructions (multi-register push/pop)

#### 3.1.2 Program Counter (PC)

**Size and Layout:**

| CPU Variant | PC Width | Valid Bits | Bit 0 | Bits [31:29] | Notes |
|-------------|----------|------------|-------|--------------|-------|
| **V850** | 24-bit | [23:1] | Always 0 | Reserved (0) | 16 MB address space |
| **V850ES/E1/E2** | 24-bit | [23:1] | Always 0 | Reserved (0) | 16 MB address space |
| **V850E2M** | 29-bit | [28:1] | Always 0 | Sign extension of bit 28 | 512 MB address space (product-dependent) |
| **RH850G3M** | 32-bit | [31:1] | Always 0 | Valid | 4 GB address space |
| **RH850G3MH** | 32-bit | [31:1] | Always 0 | Valid | 4 GB address space |

**Reset Value:**
- V850E2M: 00000000H
- RH850G3M: Product-dependent (see hardware manual)

**Key Constraints:**
- **Bit 0 always 0:** Cannot branch to odd addresses (instructions are 16-bit or 32-bit aligned)
- **Alignment:** All instructions must be 2-byte aligned (halfword boundary)
- **RETI behavior:** When RETI restores PC from EIPC/FEPC/CTPC, bit 0 is ignored (forced to 0)
- **Carry from bit 23:** On V850 (24-bit PC), carry from bit 23 to 24 is ignored

**Implementation Status:** ✅ Complete (all registers + PC implemented)

**Implementation Quality by Variant:**
- **V850/V850ES/V850E1/V850E2/V850E2M:** ✅ 100% implemented
- **RH850G3M/RH850G3MH:** ⚠️ Needs PSW.UM bit support for user/supervisor mode distinction

---

### 3.2 FPU Registers (V850E2M, V850E3, RH850G3M, RH850G3MH)

**File:** `llvm/lib/Target/V850/V850RegisterInfo.td` (Lines 83-115)

**Variants:** V850E2M, V850E2V3, V850E3, V850E3V5, RH850G3M, RH850G3MH

**Important:** The FPU **does not have dedicated register files**. It reuses CPU general-purpose registers (r0-r31).

#### 3.2.1 Floating-Point Register Organization

| Precision | Register Count | Register Naming | Register Pairs | Access Permission |
|-----------|----------------|-----------------|----------------|-------------------|
| **Single (32-bit)** | 32 registers | r0-r31 | Each register used independently | Requires PSW.CU0=1 (RH850G3M only) |
| **Double (64-bit)** | 16 register pairs | Specified by even register | {r1,r0}, {r3,r2}, ... {r31,r30} | Requires PSW.CU0=1 (RH850G3M only) |

**Register Pair Formation (Double-Precision):**
```
Specified Register → Actual Register Pair Used
--------------------------------------------------
r0  → {r1, r0}   (INVALID - r0 is zero register)
r2  → {r3, r2}
r4  → {r5, r4}
r6  → {r7, r6}
...
r30 → {r31, r30}
```

**Bit Layout:**
- **Single-precision:** 32 bits per register
- **Double-precision:** 64 bits per register pair (high 32 bits in odd register, low 32 bits in even register)

#### 3.2.2 Important Constraints

| Constraint | Description | Rationale |
|------------|-------------|-----------|
| **r0 zero register** | {r1, r0} cannot be used for double-precision | r0 always holds 0, so low 32 bits would always be 0 |
| **Even register specification** | Double-precision instructions specify only the even-numbered register | Even register implies the pair {even+1, even} |
| **No odd register specification** | Odd registers cannot be specified for double-precision | Would be ambiguous - which pair? |
| **Register pair alignment** | Pairs are fixed: {r1,r0}, {r3,r2}, {r5,r4}, etc. | Hardware limitation |
| **CU0 permission (RH850G3M)** | PSW.CU0 must be 1 to access FPU | Coprocessor 0 enable bit controls FPU access |

#### 3.2.3 Assembly Examples

```assembly
# Single-Precision Operations
addf.s r5, r6, r7          # r7 = r5 + r6 (all 32-bit)
mulf.s r10, r11, r12       # r12 = r10 * r11
cmpf.s sf, r8, r9, cc0     # Compare r8 and r9, set condition code cc0

# Double-Precision Operations
addf.d r4, r6, r8          # {r9,r8} = {r5,r4} + {r7,r6} (all 64-bit pairs)
mulf.d r10, r12, r14       # {r15,r14} = {r11,r10} * {r13,r12}
divf.d r2, r4, r6          # {r7,r6} = {r3,r2} / {r5,r4}

# INVALID Examples
addf.d r0, r2, r4          # ERROR: {r1,r0} not usable (r0 is zero)
addf.d r5, r6, r8          # ERROR: r5 is odd (must be even)
```

#### 3.2.4 FPU System Registers

FPU operation is controlled by 6 system registers (see Section 3.6 and 3.8 for details):

| RegID | selID | Symbol | Full Name | V850E2M | RH850G3M | Access |
|-------|-------|--------|-----------|---------|----------|--------|
| 6 | 0 | FPSR | FP Configuration/Status | ✅ | ✅ | R/W (CU0+SV on RH850G3M) |
| 7 | 0 | FPEPC | FP Exception PC | ✅ | ✅ | R/W (CU0+SV on RH850G3M) |
| 8 | 0 | FPST | FP Status (alias) | ✅ | ✅ | R/W (CU0 on RH850G3M) |
| 9 | 0 | FPCC | FP Condition Code (alias) | ✅ | ✅ | R/W (CU0 on RH850G3M) |
| 10 | 0 | FPCFG | FP Configuration (alias) | ✅ | ✅ | R/W (CU0 on RH850G3M) |
| 11 | 0 | FPEC | FP Exception Control | ✅ | ✅ | R/W (CU0+SV on RH850G3M) |

**Note:** FPST, FPCC, FPCFG are aliases/mirrors of specific FPSR bits for easier access.

#### 3.2.5 FPSR Register Differences by Variant

**V850E2M FPSR (RegID=6):**
```
31     30-24   23 22  21  20   19-18  17  16    15-10        9-5         4-0
┌──┬─────────┬──┬──┬───┬───┬──────┬──┬──┬────────────┬───────────┬──────────┐
│  │ CC(7:0) │  │0 │DEM│SEM│  RM  │FS│PR│  XC (6)    │  XE (5)   │ XP (5)   │
└──┴─────────┴──┴──┴───┴───┴──────┴──┴──┴────────────┴───────────┴──────────┘
31-24: CC(7:0) = Condition code bits (comparison results)
21: DEM = Double-precision Exception Mode (0=imprecise, 1=precise)
20: SEM = Single-precision Exception Mode (0=imprecise, 1=precise)
19-18: RM = Rounding Mode (00=RN only, others prohibited)
17: FS = Flush Subnormals (1=flush denormals to 0)
16: PR = Precision mode of last exception
15-10: XC = Exception Cause bits (E, V, Z, O, U, I)
9-5: XE = Exception Enable bits (V, Z, O, U, I - no E)
4-0: XP = Exception Preservation bits (V, Z, O, U, I - no E)
```

**RH850G3M FPSR (SR6, selID=0):**
```
31     30-24   23 22  21  20   19-18  17  16    15-10        9-5         4-0
┌──┬─────────┬──┬──┬───┬──┬──────┬──┬──┬────────────┬───────────┬──────────┐
│  │ CC(7:0) │FN│IF│PEM│0 │  RM  │FS│0 │  XC (6)    │  XE (5)   │ XP (5)   │
└──┴─────────┴──┴──┴───┴──┴──────┴──┴──┴────────────┴───────────┴──────────┘
31-24: CC(7:0) = Condition code bits (comparison results)
23: FN = Flush to Nearest (enhanced flush mode)
22: IF = Input Flush flag (accumulates flush information)
21: PEM = Precise Exception Mode (0=imprecise, 1=precise for all operations)
19-18: RM = Rounding Mode (00=RN, 01=RZ, 10=RP, 11=RM - all 4 modes supported!)
17: FS = Flush Subnormals (1=flush denormals)
15-10: XC = Exception Cause bits (E, V, Z, O, U, I)
9-5: XE = Exception Enable bits (V, Z, O, U, I)
4-0: XP = Exception Preservation bits (V, Z, O, U, I)
```

**Key FPSR Differences:**
- **V850E2M:** Separate DEM/SEM bits (per-precision exception mode), only RN rounding mode
- **RH850G3M:** Unified PEM bit (single exception mode for all), all 4 rounding modes (RN/RZ/RP/RM), FN/IF bits for enhanced flush handling

**Rounding Modes:**
- **RN (00):** Round to Nearest (ties to even) - supported by both
- **RZ (01):** Round toward Zero - **RH850G3M only**
- **RP (10):** Round toward +∞ - **RH850G3M only**
- **RM (11):** Round toward −∞ - **RH850G3M only**

#### 3.2.6 Exception Bit Definitions (XC, XE, XP)

| Bit Position | Symbol | Exception Type | Description |
|--------------|--------|----------------|-------------|
| 15/10/5 | E | Unimplemented | Software emulation required (no enable/preservation bit) |
| 14/9/4 | V | Invalid Operation | Invalid operand (NaN arithmetic, √negative, etc.) |
| 13/8/3 | Z | Divide by Zero | Division by zero |
| 12/7/2 | O | Overflow | Result too large for format |
| 11/6/1 | U | Underflow | Result too small for format |
| 10/5/0 | I | Inexact | Result not exactly representable |

**Implementation Status:**
- **FPU Register Model:** ✅ Complete (single/double precision aliasing fully implemented)
- **V850E2M FPSR:** ✅ Complete (all bits implemented)
- **RH850G3M FPSR:** ⚠️ Partial (missing FN, IF, PEM bits, only RN rounding mode implemented)
- **RH850G3M Access Control:** ❌ PSW.CU0 checking not implemented

**Priority:** Medium (RH850G3M FPSR enhancements needed for full IEEE754 compliance)

---

### 3.3 System Registers - Overview

System registers are accessed via `LDSR reg2, regID[, selID]` and `STSR regID, reg2[, selID]` instructions.

**Register Numbering Models:**
- **V850/V850ES/V850E1/V850E2/V850E2M:** RegID only (0-31)
- **RH850G3M/RH850G3MH:** (RegID, selID) pair for extended register space

**Bank Selection Models:**
- **V850E2M:** BSEL-based banking (group + bank number)
- **RH850G3M:** selID-based groups (cleaner model)

---

### 3.4 Base System Registers (V850/V850ES/V850E1)

**Variants:** V850, V850ES, V850E1, V850E2, V850E2M, V850E3, RH850G3M

**File:** `llvm/lib/Target/V850/V850RegisterInfo.td` (Lines 157-190)

| RegID | Name | Full Name | Size | Access | Reset Value | Description |
|-------|------|-----------|------|--------|-------------|-------------|
| **0** | EIPC | Exception/Interrupt PC | 24-bit | R/W | Undefined | Saves PC when EI-level exception occurs. Bits [23:1] valid, bit 0 ignored on RETI |
| **1** | EIPSW | Exception/Interrupt PSW | 32-bit | R/W | Undefined | Saves PSW when EI-level exception occurs |
| **2** | FEPC | Fatal Error PC | 24-bit | R/W | Undefined | Saves PC when FE-level exception (NMI) occurs. Bits [23:1] valid |
| **3** | FEPSW | Fatal Error PSW | 32-bit | R/W | Undefined | Saves PSW when FE-level exception (NMI) occurs |
| **4** | ECR | Exception Cause Register | 32-bit | **R** | Undefined | Holds exception/interrupt cause code. **Read-only**. Bits [31:16]=FECC (NMI code), bits [15:0]=EICC (exception/interrupt code) |
| **5** | PSW | Program Status Word | 32-bit | R/W | 00000020H | CPU status flags. Bits [7:0] = flags (NP, EP, ID, SAT, CY, OV, S, Z) |
| **6-15** | - | Reserved | - | - | - | Reserved for future expansion |

**PSW Bit Layout (Base V850):**
```
31                                8 7  6  5  4   3  2  1  0
┌────────────────────────────────┬──┬──┬──┬───┬──┬──┬──┬──┐
│          RFU (0)               │NP│EP│ID│SAT│CY│OV│S │Z │
└────────────────────────────────┴──┴──┴──┴───┴──┴──┴──┴──┘
```

**PSW Flag Descriptions:**
- **Z (bit 0):** Zero flag (1 = result is zero)
- **S (bit 1):** Sign flag (1 = result is negative)
- **OV (bit 2):** Overflow flag (1 = overflow occurred)
- **CY (bit 3):** Carry/borrow flag
- **SAT (bit 4):** Saturation flag (cumulative, set by saturation operations)
- **ID (bit 5):** Interrupt disable (1 = interrupts masked)
- **EP (bit 6):** Exception pending (1 = exception processing in progress)
- **NP (bit 7):** NMI pending (1 = NMI processing in progress, masks multiple interrupts)

**Implementation Status:** ✅ Complete (6/6 registers, all variants)

**V850ES Note:** V850ES uses **only these 6 registers** (does not have V850E1 additional registers)

---

### 3.5 V850E1 Additional System Registers

**Variants:** V850E1, V850E2, V850E2M, V850E3 (**NOT V850ES**)

**File:** `llvm/lib/Target/V850/V850RegisterInfo.td` (Lines 191-220)

| RegID | Name | Full Name | Size | Access | Reset Value | Description | Impl Status |
|-------|------|-----------|------|--------|-------------|-------------|-------------|
| **16** | CTPC | CALLT PC | 24-bit | R/W | Undefined | Saves PC when CALLT executed | ✅ Implemented |
| **17** | CTPSW | CALLT PSW | 32-bit | R/W | Undefined | Saves PSW when CALLT executed | ✅ Implemented |
| **18** | DBPC | Debug PC | 24-bit | R/W | Undefined | Saves PC for debug trap (Type A/B products only) | ✅ Implemented |
| **19** | DBPSW | Debug PSW | 32-bit | R/W | Undefined | Saves PSW for debug trap (Type A/B products only) | ✅ Implemented |
| **20** | CTBP | CALLT Base Pointer | 32-bit | R/W | Undefined | Base address for CALLT table. Bits [31:9] valid, bits [8:0] = 0 | ✅ Implemented |
| **21** | DIR | Debug Interface Register | 32-bit | R/W | Undefined | Debug mode control (Type A/B only) | ✅ Implemented |
| **22** | BPC0/BPC1 | Breakpoint Control 0/1 | 32-bit | R/W | Undefined | Breakpoint control (selected by DIR.CS) | ✅ Implemented |
| **23** | ASID | Address Space ID | 32-bit | R/W | Undefined | Process ID for MMU/debug | ✅ Implemented |
| **24** | BPAV0/BPAV1 | Breakpoint Address Value 0/1 | 32-bit | R/W | Undefined | Breakpoint address (selected by DIR.CS) | ✅ Implemented |
| **25** | BPAM0/BPAM1 | Breakpoint Address Mask 0/1 | 32-bit | R/W | Undefined | Breakpoint address mask (selected by DIR.CS) | ✅ Implemented |
| **26** | BPDV0/BPDV1 | Breakpoint Data Value 0/1 | 32-bit | R/W | Undefined | Breakpoint data value (selected by DIR.CS) | ✅ Implemented |
| **27** | BPDM0/BPDM1 | Breakpoint Data Mask 0/1 | 32-bit | R/W | Undefined | Breakpoint data mask (selected by DIR.CS) | ✅ Implemented |

**Implementation Status:** ✅ Complete (12/12 implemented, 100%)

**Priority:** Low (debug registers, not required for code generation)

**Note:** DIR.CS bit selects between register pair 0 and 1 for BPC, BPAV, BPAM, BPDV, BPDM

---

### 3.6 V850E2M System Registers

**Variants:** V850E2M, V850E3

**File:** `llvm/lib/Target/V850/V850RegisterInfo.td` (Lines 220-245)

| RegID | Name | Full Name | Size | Access | Reset Value | Description | Impl Status |
|-------|------|-----------|------|--------|-------------|-------------|-------------|
| **6** | FPSR | FP Configuration/Status | 32-bit | R/W | Note | FPU status and control. CC bits [31:24], exception mode, rounding, cause, enable, preservation | ✅ Implemented |
| **7** | FPEPC | FP Exception PC | 32-bit | R/W | Undefined | Saves PC when FPU exception occurs | ✅ Implemented |
| **8** | FPST | FP Status | 32-bit | R/W | 00000000H | Alias for FPSR.RM and FPSR.XE bits | ✅ Implemented |
| **9** | FPCC | FP Condition Code | 32-bit | R/W | Undefined | Alias for FPSR.CC[7:0] bits | ✅ Implemented |
| **10** | FPCFG | FP Configuration | 32-bit | R/W | 00000000H | Alias for FPSR.RM and FPSR.FS bits | ✅ Implemented |
| **11** | FPEC | FP Exception Control | 32-bit | R/W | 00000000H | Controls FPI exception checking/canceling | ✅ Implemented |
| **11** | SCCFG | SYSCALL Config (alt) | 32-bit | R/W | 00000000H | SYSCALL operation setting (same RegID as FPEC) | ✅ Implemented |
| **12** | SCBP | SYSCALL Base Pointer | 32-bit | R/W | Undefined | Base address for SYSCALL table | ✅ Implemented |
| **13** | EIIC | EI Interrupt Cause | 32-bit | R/W | Undefined | EI-level exception cause code | ✅ Implemented |
| **14** | FEIC | FE Interrupt Cause | 32-bit | R/W | Undefined | FE-level exception cause code | ✅ Implemented |
| **15** | DBIC | DB Interrupt Cause | 32-bit | R/W | Undefined | Debug exception cause code | ✅ Implemented |
| **28** | EIWR | EI Working Register | 32-bit | R/W | Undefined | EI-level exception working register | ✅ Implemented |
| **29** | FEWR | FE Working Register | 32-bit | R/W | Undefined | FE-level exception working register | ✅ Implemented |
| **30** | DBWR | DB Working Register | 32-bit | R/W | Undefined | Debug working register | ✅ Implemented |
| **31** | BSEL | Bank Selection | 32-bit | R/W | 00000000H | System register bank selection | ✅ Implemented |

**Implementation Status:** ✅ Complete (14/14 implemented, 100%)

**Priority:** Medium (EIIC, FEIC useful for exception handling)

**PSW Extensions for V850E2M:**
```
31   20 19 18 17 16 15   8 7  6  5  4  3  2  1  0
┌────┬──┬──┬──┬──┬────┬──┬──┬──┬──┬──┬──┬──┬──┐
│ 0  │PP│NP│DM│IM│  0 │NP│EP│ID│SA│CY│OV│S │Z │
│    │  │V │P │P │    │  │  │  │T │  │  │  │  │
└────┴──┴──┴──┴──┴────┴──┴──┴──┴──┴──┴──┴──┴──┘
```

**New PSW Bits (V850E2M):**
- **PP (bit 19):** Processor protection mode (interacts with MPM.AUE)
- **NPV (bit 18):** Non-privileged mode
- **DMP (bit 17):** Data memory protection enable
- **IMP (bit 16):** Instruction memory protection enable

---

### 3.7 V850E2M Register Banking (BSEL-based)

**Status:** ❌ Not Implemented (registers defined, but banking not used by LDSR/STSR)

**Documentation:** V850InstructionReference.md lines 726-1151

V850E2M uses BSEL register to select register banks:

| BSEL Value | Group | Bank Label | Description |
|------------|-------|------------|-------------|
| **0x0000** | 0 | CPU Main | All standard system registers |
| **0x0010** | 0 | EHSW0 | Exception Handler Switching Bank 0 |
| **0x0011** | 0 | EHSW1 | Exception Handler Switching Bank 1 |
| **0x1000-0x1010** | 16 | Processor Protection | MPM, MPRC, protection registers |
| **0x2000** | 32 | FPU Status | FPSR, FPEPC, FPST, FPCC, FPCFG, FPEC |
| **0xFF00-0xFFFF** | 255 | User Banks | User-defined register banks |

**Issue:** BSEL register exists (RegID 31) but LDSR/STSR don't validate or use bank selection. FPU system registers and protection registers cannot be accessed via banking.

**Priority:** Low (primarily for OS/RTOS support)

---

### 3.8 RH850G3M System Registers (selID-based)

**Variants:** RH850G3M, RH850G3MH

**Status:** ❌ **NOT Implemented** (no RH850G3M support in LLVM)

**Documentation:** V850InstructionReference.md lines 763-804, RH850G3M software manual

RH850G3M uses **(regID, selID)** register numbering:
- **LDSR syntax:** `LDSR reg2, regID, selID`
- **STSR syntax:** `STSR regID, reg2, selID`

#### 3.8.1 Basic System Registers (selID=0)

| RegID | selID | Symbol | Full Name | Access | Description |
|-------|-------|--------|-----------|--------|-------------|
| 0 | 0 | EIPC | EI Exception PC | SV | Status save when acknowledging EI exception |
| 1 | 0 | EIPSW | EI Exception PSW | SV | Status save when acknowledging EI exception |
| 2 | 0 | FEPC | FE Exception PC | SV | Status save when acknowledging FE exception |
| 3 | 0 | FEPSW | FE Exception PSW | SV | Status save when acknowledging FE exception |
| 5 | 0 | PSW | Program Status Word | Note 1 | CPU status (with RH850G3M extensions) |
| 6 | 0 | FPSR | FP Configuration/Status | CU0+SV | FPU status and control |
| 7 | 0 | FPEPC | FP Exception PC | CU0+SV | FPU exception program counter |
| 8 | 0 | FPST | FP Status | CU0 | Alias for FPSR bits |
| 9 | 0 | FPCC | FP Condition Code | CU0 | Alias for FPSR.CC bits |
| 10 | 0 | FPCFG | FP Configuration | CU0 | Alias for FPSR bits |
| 11 | 0 | FPEC | FP Exception Control | CU0+SV | FPU exception control |
| 13 | 0 | EIIC | EI Interrupt Cause | SV | EI-level exception cause |
| 14 | 0 | FEIC | FE Interrupt Cause | SV | FE-level exception cause |
| 16 | 0 | CTPC | CALLT PC | UM | CALLT execution status save |
| 17 | 0 | CTPSW | CALLT PSW | UM | CALLT execution status save |
| 20 | 0 | CTBP | CALLT Base Pointer | UM | CALLT base pointer |
| 28 | 0 | EIWR | EI Working Register | SV | EI-level exception working register |
| 29 | 0 | FEWR | FE Working Register | SV | FE-level exception working register |
| 31 | 0 | BSEL (compat) | Bank Selection (compat) | SV | Reserved for V850E2 compatibility (always 0) |

**Access Permissions:**
- **SV:** Supervisor mode only
- **UM:** User mode accessible
- **CU0:** Requires PSW.CU0=1 (Coprocessor 0 enable)

#### 3.8.2 Basic System Registers (selID=1)

| RegID | selID | Symbol | Full Name | Access | Description |
|-------|-------|--------|-----------|--------|-------------|
| 0 | 1 | MCFG0 | Machine Configuration | SV | Machine configuration |
| 2 | 1 | RBASE | Reset Base Address | SV | Reset vector base address |
| 3 | 1 | EBASE | Exception Base Address | SV | Exception handler vector address |
| 4 | 1 | INTBP | Interrupt Base Pointer | SV | Base address of interrupt handler table |
| 5 | 1 | MCTL | CPU Control | SV | CPU control register |
| 6 | 1 | PID | Processor ID | SV | Processor ID |
| 11 | 1 | SCCFG | SYSCALL Config | SV | SYSCALL operation setting |
| 12 | 1 | SCBP | SYSCALL Base Pointer | SV | SYSCALL base pointer |

#### 3.8.3 Basic System Registers (selID=2)

| RegID | selID | Symbol | Full Name | Access | Description |
|-------|-------|--------|-----------|--------|-------------|
| 0 | 2 | HTCFG0 | Thread Configuration | SV | Hardware thread configuration |
| 6 | 2 | MEA | Memory Error Address | SV | Memory error address |
| 7 | 2 | ASID | Address Space ID | SV | Address space ID (MMU) |
| 8 | 2 | MEI | Memory Error Information | SV | Memory error information |

#### 3.8.4 Interrupt Function System Registers (selID=1 or 2)

| RegID | selID | Symbol | Full Name | Access | Description |
|-------|-------|--------|-----------|--------|-------------|
| 7 | 1 | FPIPR | FPI Priority | SV | FPI exception interrupt priority setting |
| 10 | 2 | ISPR | Interrupt Service Priority | SV | Priority of interrupt being serviced |
| 11 | 2 | PMR | Priority Mask Register | SV | Interrupt priority masking |
| 12 | 2 | ICSR | Interrupt Control Status | SV | Interrupt control status |
| 13 | 2 | INTCFG | Interrupt Configuration | SV | Interrupt function setting |

#### 3.8.5 MPU Function System Registers (selID=2)

| RegID | selID | Symbol | Full Name | Access | Description |
|-------|-------|--------|-----------|--------|-------------|
| 0 | 2 | MPM | Memory Protection Mode | SV | Memory protection mode control |
| 1 | 2 | MPRC | Memory Protection Region Count | SV | Number of memory protection regions |
| 4-15 | 2 | MPLAn | Memory Protection Lower Address | SV | Lower address for protection region n |
| 16-27 | 2 | MPUAn | Memory Protection Upper Address | SV | Upper address for protection region n |
| 20-31 | 2 | MPATn | Memory Protection Attributes | SV | Attributes for protection region n |

**Note:** Specific RegIDs vary by region number n (0-15 for different protection regions)

#### 3.8.6 Cache Control System Registers (selID=5)

| RegID | selID | Symbol | Full Name | Access | Description |
|-------|-------|--------|-----------|--------|-------------|
| 0 | 5 | ICCTRL | Instruction Cache Control | SV | Instruction cache control |
| 1 | 5 | ICERR | Instruction Cache Error | SV | Instruction cache error status |
| 2 | 5 | ICCFG | Instruction Cache Config | SV | Instruction cache configuration |
| 3 | 5 | ICTAGL | Instruction Cache Tag Low | SV | Instruction cache tag (low) |
| 4 | 5 | ICTAGH | Instruction Cache Tag High | SV | Instruction cache tag (high) |
| 5 | 5 | ICDATL | Instruction Cache Data Low | SV | Instruction cache data (low) |
| 6 | 5 | ICDATH | Instruction Cache Data High | SV | Instruction cache data (high) |

**RH850G3M PSW Extensions:**
```
31 30 29   19 18 17 16 15 14 12 11 10 9 8 7  6  5  4  3  2  1  0
┌──┬──┬────┬──┬──┬──┬──┬────┬─────────┬─┬──┬──┬──┬──┬──┬──┬──┬──┐
│0 │UM│ 0  │C │C │C │EB│  0 │  Debug  │0│NP│EP│ID│SA│CY│OV│S │Z │
│  │  │    │U2│U1│U0│V │    │         │ │  │  │  │T │  │  │  │  │
└──┴──┴────┴──┴──┴──┴──┴────┴─────────┴─┴──┴──┴──┴──┴──┴──┴──┴──┘
```

**New PSW Bits (RH850G3M):**
- **UM (bit 30):** User mode (0=Supervisor, 1=User)
- **CU2 (bit 18):** Coprocessor 2 enable
- **CU1 (bit 17):** Coprocessor 1 enable
- **CU0 (bit 16):** Coprocessor 0 enable (FPU access)
- **EBV (bit 15):** Exception base vector selection
- **Debug (bits 11-9):** Debug status field

**Implementation Status:** ❌ **0% Implemented** - No RH850G3M support

**Critical Issues:**
1. LDSR/STSR have no selID operand
2. RH850G3M system registers not defined
3. Parser doesn't recognize 3-operand LDSR/STSR syntax
4. PSW extensions (UM, CU0-CU2, EBV, Debug) not implemented

**Priority:** **Critical** for RH850G3M support

---

## 3.9 System Register Summary by CPU Variant

| CPU Variant | RegID Range | selID Support | Banking | Total Registers | Impl Status |
|-------------|-------------|---------------|---------|-----------------|-------------|
| **V850** | 0-5 | No | No | 6 | ✅ 100% |
| **V850ES** | 0-5 | No | No | 6 | ✅ 100% |
| **V850E1** | 0-5, 16-27 | No | No | 18 | ✅ 100% (18/18) |
| **V850E2** | 0-5, 16-27 | No | No | 18 | ✅ 100% (18/18) |
| **V850E2M** | 0-5, 6-15, 16-27, 28-31 | No | BSEL-based | 32 | ✅ 100% (32/32) |
| **RH850G3M** | (regID, selID) pairs | Yes | selID groups | 50+ | ❌ 0% |
| **RH850G3MH** | (regID, selID) pairs | Yes | selID groups | 50+ | ❌ 0% |

**Key Findings:**
- V850/V850ES/V850E1/V850E2/V850E2M: ✅ Complete (all system registers implemented)
- V850E2M: ⚠️ Register banking not used (BSEL-based access not implemented)
- RH850G3M/G3MH: ❌ Completely missing
### 4.1 Current Scheduling Models

**Files:**
- `llvm/lib/Target/V850/V850Schedule.td` - V850 base model (5-stage single-issue)
- `llvm/lib/Target/V850/V850SchedV850E1.td` - V850ES/E1 model (5-stage single-issue, different MUL/branch timing)
- `llvm/lib/Target/V850/V850SchedV850E2M.td` - V850E2/E2M model (7-stage dual-issue with Lpipe/Rpipe)

### 4.2 Pipeline Characteristics vs Documentation

**Reference:** V850CycleTimings.md lines 7-16

| CPU Variant | Pipeline | Dual Issue | Branch Pred | Documented | Implemented | Status |
|-------------|----------|------------|-------------|------------|-------------|--------|
| V850 | 5-stage | No | No | V850CycleTimings.md | V850Model | ✅ Complete |
| V850ES/E1 | 5-stage | No | No | V850CycleTimings.md | V850E1Model | ✅ Complete |
| V850E2 | **7-stage** | **Yes (L/R)** | No | V850CycleTimings.md | V850E2MModel | ✅ Complete |
| V850E2M | **7-stage** | **Yes (L/R)** | No | V850CycleTimings.md | V850E2MModel | ✅ Complete |
| RH850G3M | 7-stage | Yes | **Yes** | V850CycleTimings.md | - | ❌ **Not Implemented** |
| RH850G3MH | 7+ stage | Yes | **Yes** | V850CycleTimings.md | - | ❌ **Not Implemented** |

**Scheduling Model Summary (Updated 2026-01-11):**

| Model | Used By | IssueWidth | Pipeline Resources | Key Characteristics |
|-------|---------|------------|-------------------|-------------------|
| V850Model | v850, generic | 1 | ALU, Mem, Branch, Mul, Div | Base model, MUL: 2 cycles, Branch: 3 cycles |
| V850E1Model | v850es, v850e1 | 1 | ALU, Mem, Branch, Mul, Div | MUL: 5 cycles (1-4-5), Branch: 2 cycles |
| V850E2MModel | v850e2, v850e2m, v850e2v3, v850e3, v850e3v5 | 2 | Lpipe, Rpipe, AnyPipe, Branch, Div, FPALU, FPDiv | Dual-issue with Lpipe/Rpipe, Load: 3 cycles, FPU support |

### 4.3 Instruction Latency Discrepancies

**Reference:** V850CycleTimings.md, comparing against V850Schedule.td

#### Load Instructions ✅ (Fixed 2026-01-11)

| Instruction | V850 Doc | V850E1 Doc | V850E2M Doc | V850Model | V850E1Model | V850E2MModel | Status |
|-------------|----------|------------|-------------|-----------|-------------|--------------|--------|
| LD.B/H/W | 1-1-2 | 1-1-2 | 1-1-3* | Latency=2 | Latency=2 | Latency=3 | ✅ Correct |
| SLD.B/H/W | 1-1-2 | 1-1-1 | 1-1-3* | Latency=2 | Latency=2 | Latency=3 | ✅ Correct |
| LD.BU/HU | N/A | 1-1-2* | 1-1-3* | N/A | Latency=2 | Latency=3 | ✅ Correct |

**Files:** V850Schedule.td, V850SchedV850E1.td, V850SchedV850E2M.td

#### Multiply/Divide Instructions ✅ (Updated 2026-01-11)

| Instruction | V850 Doc | V850E1 Doc | V850E2 Doc | V850Model | V850E1Model | V850E2MModel | Status |
|-------------|----------|------------|------------|-----------|-------------|--------------|--------|
| MULH | 1-1-2 | 1-1-2 | 1-1-3 | Lat=2 | Lat=2 | Lat=3 | ✅ Correct |
| MUL (3-op) | N/A | 1-4-5 | 1-1-3 | N/A | Lat=5, Rep=4 | Lat=3 | ✅ Correct |
| DIV | N/A | 35-35-35 | 36-36-36 | Lat=36 | Lat=35 | Lat=36 | ✅ Correct |
| DIVQ | N/A | N/A | N+5* | N/A | N/A | Lat=12 (avg) | ⚠️ Fixed estimate |
| DIVQU | N/A | N/A | N+4* | N/A | N/A | Lat=12 (avg) | ⚠️ Fixed estimate |

**Reference:** V850CycleTimings.md lines 150-168
**Files:** V850Schedule.td, V850SchedV850E1.td, V850SchedV850E2M.td

**Note:** DIVQ/DIVQU have variable cycles (N = valid bits of dividend - valid bits of divisor, range 0-16). Fixed Latency=12 is a conservative estimate for average case.

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

### 4.4 Resource Classes ✅ (Implemented 2026-01-11)

**Reference:** V850CycleTimings.md lines 334-367

**V850E2/V850E2M Dual-Issue Pipeline (NOW MODELED):**

According to documentation, V850E2+ have:
- **Lpipe:** Load/store, multiply, MAC
- **Rpipe:** ALU, shift, data manipulation, bit search
- **Both pipes:** Can execute many arithmetic/logical ops in parallel

**Current Implementation (V850SchedV850E2M.td):**
```tablegen
// Dual-issue pipe resources
def V850E2MLpipe        : ProcResource<1>;  // L-pipe (load/store, mul, MAC)
def V850E2MRpipe        : ProcResource<1>;  // R-pipe (ALU, shift, bit search)
def V850E2MAnyPipe      : ProcResource<2>;  // Either pipe (most ALU ops)
def V850E2MUnitBranch   : ProcResource<1>;  // Branch unit
def V850E2MUnitFPALU    : ProcResource<1>;  // FP ALU
def V850E2MUnitDiv      : ProcResource<1>;  // Integer divide (blocking)
def V850E2MUnitFPDiv    : ProcResource<1>;  // FP divide/sqrt (not pipelined)
```

**Resource Assignment:**
- **Lpipe:** Load/store (WriteLDB/H/W, WriteSTB/H/W), Multiply (WriteIMul), MAC (WriteIMAC), Bit manipulation (WriteBit), FP load/store
- **Rpipe:** Shift (WriteShift, WriteShiftReg), Data manipulation (WriteExt, WriteBSW), Bit search (WriteSCH)
- **AnyPipe:** Most ALU operations (WriteIALU, WriteIALUimm, WriteMOV, WriteCMP, WriteSat, WriteCMOV)

**Status:** ✅ Complete - Dual-issue now modeled with proper Lpipe/Rpipe resource constraints

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

**Status:** ❌ Missing V850ES feature flag

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

**Status:** ❌ V850ES-V850E1 missing in implication chain
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

**Estimated Effort:** 1-2 weeks (reduced - partial completion)

#### 3.1 V850E2/V850E2M Dual-Issue Pipeline Model ✅ (Completed 2026-01-11)

**Files:**
- `llvm/lib/Target/V850/V850SchedV850E2M.td` - Updated with Lpipe/Rpipe resources
- `llvm/lib/Target/V850/V850SchedV850E1.td` - New file for V850ES/E1 variants
- `llvm/lib/Target/V850/V850Schedule.td` - Updated base V850 model

**Completed Tasks:**
1. ✅ Defined Lpipe and Rpipe resources in V850E2MModel
2. ✅ Updated instruction definitions with pipe assignments:
   - Lpipe: Load/store, multiply, MAC, bit manipulation
   - Rpipe: Shift, data manipulation, bit search
   - AnyPipe: Most arithmetic/logical ops (can use either)
3. ✅ Set IssueWidth=2 for dual-issue
4. ✅ Created separate V850E1Model for V850ES/E1 with different MUL/branch timing
5. ✅ Updated all load/branch latencies per V850CycleTimings.md

**Reference:** V850CycleTimings.md lines 334-367

**Status:** ✅ Complete

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

**Status:** ✅ Mostly Complete (updated in commit 96e8a965174e, RH850G4MH variants added 2026-01-11)

Remaining updates:
1. ✅ Complete opcode summary for all instructions (DONE)
2. ✅ Add FPU instruction opcode tables (DONE)
3. ✅ Add RH850G4MH/RH850G4MH2 CPU variants to overview (DONE 2026-01-11)
4. ⚠️ Add RH850G3M instruction descriptions when implemented
5. ⚠️ Add RH850G4MH-specific instruction descriptions (LDM.MP, STM.MP, HVTRAP, LDM.GSR, STM.GSR) when implemented
6. ⚠️ Update system register table with selID-based access model

### 10.2 V850CycleTimings.md

**Status:** ✅ Complete (RH850G4MH/RH850G4MH2 columns added 2026-01-11)

Recent updates:
- Added RH850G4MH and RH850G4MH2 columns to all instruction timing tables
- Added MPU Entry Load/Store section with LDM.MP/STM.MP timing information
- Added Virtualization Instructions section with HVTRAP, LDM.GSR, STM.GSR timings
- All timing values based on RH850G4MH/RH850G4MH2 User's Manual specifications

### 10.3 V850HazardManagement.md

**Status:** ✅ Complete (RH850G4MH/RH850G4MH2 added 2026-01-11)

Recent updates:
- Added RH850G4MH and RH850G4MH2 to pipeline architecture summary
- Added RH850G4MH-Specific Hazards section covering:
  - MPU Entry Load/Store Instructions (LDM.MP/STM.MP) hazards
  - Virtualization hazards (mode transitions, HVTRAP, LDM.GSR/STM.GSR)
  - Required synchronization for MPU and virtualization operations

### 10.4 LLVM User Documentation

**Files to Create/Update:**
1. `llvm/docs/V850TargetGuide.rst` (new) - V850 backend user guide
2. `clang/docs/V850Options.rst` (new) - Clang V850-specific options

Content needed:
- Supported CPU variants (v850, v850e1, v850e2, v850e2m, rh850g3m, rh850g3mh, rh850g4mh, rh850g4mh2)
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
- **V850:** 100% complete, production-ready ✅ (base 74 instructions, 6 system registers)
- **V850ES:** 100% complete, production-ready ✅ (same ISA as V850E1, 6 system registers only)
- **V850E1:** 100% complete, production-ready ✅ (V850ES ISA + 18 system registers including debug/CALLT)
- **V850E2/V850E2M:** 100% complete, production-ready ✅ (all instructions and 32 system registers)
- **RH850G3M/G3MH:** 0% complete, requires significant work ❌

**Key Architecture Distinction: V850ES vs V850E1**

V850ES and V850E1 share the same instruction set architecture (ISA) but differ in system register availability:

- **V850ES:** Extended ISA + 6 base system registers (EIPC, EIPSW, FEPC, FEPSW, ECR, PSW)
- **V850E1:** Extended ISA + 18 system registers (6 base + 12 additional for CALLT and debug)

Both use `FeatureV850E1` in the compiler as they share the same instruction set. The compiler does not enforce system register restrictions at compile time - this is a hardware-level distinction.

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
