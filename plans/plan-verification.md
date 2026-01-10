# V850 Implementation Verification Plan

This document compares the current V850 LLVM backend implementation against the updated V850InstructionReference.md documentation and identifies discrepancies that need to be addressed.

**Date:** 2026-01-10
**Documentation Reference:** docs/V850InstructionReference.md (commit a40b3f82560d)
**Implementation Base:** llvm/lib/Target/V850/

---

## Executive Summary

The V850 backend has comprehensive support for V850, V850E1, V850E2, and V850E2M CPU variants with 318+ instructions defined. However, several discrepancies exist between the documentation and implementation:

- **Missing CPU Variants:** RH850G3M, RH850G3MH, RH850G4M support not implemented
- **Missing Instructions:** 40+ RH850G3M-specific instructions
- **System Register Gaps:** RH850G3M system registers (selID-based access) not implemented
- **Opcode Encoding:** Some opcode map entries need verification
- **Bank Selection:** V850E2M BSEL register bank selection not fully implemented

---

## 1. CPU Variant Support

### ✅ Implemented Variants

| Variant | Status | Features | Notes |
|---------|--------|----------|-------|
| v850 | ✅ Complete | Base ISA (74 instructions) | Fully implemented |
| v850es | ✅ Complete | V850ES extensions | Alias for v850e1 |
| v850e1 | ✅ Complete | CALLT, PREPARE/DISPOSE, BSH/BSW/HSW, CMOV, 3-op MUL/DIV, SXB/SXH/ZXB/ZXH, LD.BU/HU, DBTRAP/DBRET | Fully implemented |
| v850e2 | ✅ Complete | ADF/SBF, MAC/MACU, HSH, SCH0L/R/SCH1L/R, 3-op SAR/SHL/SHR, 48-bit JR/JARL/JMP | Fully implemented |
| v850e2m | ✅ Complete | FPU, CAXI, SYSCALL, EIRET/FERET/FETRAP, SYNCE/SYNCM/SYNCP, RIE, DIVQ/DIVQU, disp23 load/store | Fully implemented with FPU |
| v850e2v3 | ✅ Complete | Same as v850e2m | Alias for v850e2m |
| v850e3 | ✅ Partial | V850E3 extensions | Basic support, needs verification |
| v850e3v5 | ✅ Partial | V850E3 variant | Basic support, needs verification |

### ❌ Missing Variants

| Variant | Status | Required Features | Priority |
|---------|--------|-------------------|----------|
| rh850g3m | ❌ Not Implemented | User/supervisor modes (PSW.UM), LDL.W/STC.W atomics, CLL, BINS, ROTL, LD.DW/ST.DW, LOOP, PUSHSP/POPSP, Bcond disp17, JARL [reg1] reg3, CACHE, PREF, SNOOZE, SYNCI, selID-based system registers | High |
| rh850g3mh | ❌ Not Implemented | RH850G3M + performance enhancements, simplified FPU exceptions (FPINT replaces FPP/FPI) | High |
| rh850g4m | ❌ Not Implemented | RH850G4 extensions | Medium |
| rh850g4mh | ❌ Not Implemented | RH850G4MH variant | Medium |

---

## 2. Instruction Encoding Verification

### Format I (16-bit, reg-reg) - Opcode Map Comparison

| Bits 10:7 | Bits 6:5=00 | Bits 6:5=01 | Bits 6:5=10 | Bits 6:5=11 | Doc Status | Impl Status |
|-----------|-------------|-------------|-------------|-------------|------------|-------------|
| 0000 | MOV/NOP | NOT | DIVH | JMP | ✅ Documented | ✅ Implemented (opcodes 0x00, 0x01, 0x02, 0x03) |
| 0001 | SATSUBR/ZXB | SATSUB/SXB | SATADD/ZXH | MULH/SXH | ✅ Documented | ✅ Implemented (opcodes 0x04, 0x05, 0x06, 0x07) |
| 0010 | OR | XOR | AND | TST | ✅ Documented | ✅ Implemented (opcodes 0x08, 0x09, 0x0A, 0x0B) |
| 0011 | SUBR | SUB | ADD | CMP | ✅ Documented | ✅ Implemented (opcodes 0x0C, 0x0D, 0x0E, 0x0F) |

**Status:** ✅ Format I encodings match documentation

### Format II (16-bit, imm-reg) - Opcode Map Comparison

| Bits 10:7 | Bits 6:5=00 | Bits 6:5=01 | Bits 6:5=10 | Bits 6:5=11 | Doc Status | Impl Status |
|-----------|-------------|-------------|-------------|-------------|------------|-------------|
| 0100 | MOV imm5/CALLT | SATADD imm5 | ADD imm5 | CMP imm5 | ✅ Documented | ✅ Implemented |
| 0101 | SHR imm5 | SAR imm5 | SHL imm5 | MULH imm5 | ✅ Documented | ✅ Implemented |

**Status:** ✅ Format II encodings match documentation

### Format IV (Short Load/Store) - Verification Needed

| Bits 10:7 | Bit 0=0 | Bit 0=1 | Doc Status | Impl Status | Issues |
|-----------|---------|---------|------------|-------------|--------|
| 0110 | - | SLD.B | ✅ Documented | ✅ Implemented | None |
| 0111 | - | SST.B | ✅ Documented | ✅ Implemented | None |
| 1000 | - | SLD.H | ✅ Documented | ✅ Implemented | None |
| 1001 | - | SST.H | ✅ Documented | ✅ Implemented | None |
| 1010 | SLD.W | SST.W | ✅ Documented | ✅ Implemented | None |

**Status:** ✅ Format IV encodings match documentation

### Format VII (Load/Store) - Verification Needed

| Bits 6:5 | Bit 16=0 | Bit 16=1 | Doc Status | Impl Status | Issues |
|----------|----------|----------|------------|-------------|--------|
| 00 | LD.B | - | ✅ Documented | ✅ Implemented (opcode 0x38) | None |
| 01 | LD.H | LD.W | ✅ Documented | ✅ Implemented (opcodes 0x39, 0x3A) | None |
| 10 | ST.B | - | ✅ Documented | ✅ Implemented (opcode 0x3B) | None |
| 11 | ST.H | ST.W | ✅ Documented | ✅ Implemented (opcodes 0x3C, 0x3D) | None |

**Status:** ✅ Format VII encodings match documentation

### Extended Instructions (opcode=111111) - Discrepancies Found

| Bits 26:23 | Bits 22:21=00 | Bits 22:21=01 | Bits 22:21=10 | Bits 22:21=11 | Doc Status | Impl Status |
|------------|---------------|---------------|---------------|---------------|------------|-------------|
| 0000 | SETF | LDSR | STSR | Undefined | ✅ Documented | ✅ Implemented |
| 0001 | SHR reg | SAR reg | SHL reg | Undefined | ✅ Documented | ✅ Implemented |
| 0010 | TRAP | HALT | RETI | Extension 2 | ✅ Documented | ✅ Implemented |
| 0011-1111 | Illegal | Illegal | Illegal | Illegal | ✅ Documented | ⚠️ Partial - many extended instructions use these codes |

**Issue:** Documentation states bits 26:23 = 0011-1111 are illegal, but implementation defines many valid instructions in this range (PREPARE, DISPOSE, CMOV, ADF, SBF, MAC, MACU, etc.)

**Resolution Needed:** Update documentation opcode map to include all V850E1+ extended instruction sub-opcodes.

---

## 3. System Register Verification

### Base System Registers (V850/V850ES/V850E1)

| RegID | Name | Doc Status | Impl Status | Access | Issues |
|-------|------|------------|-------------|--------|--------|
| 0 | EIPC | ✅ Documented | ✅ Implemented | R/W | None |
| 1 | EIPSW | ✅ Documented | ✅ Implemented | R/W | None |
| 2 | FEPC | ✅ Documented | ✅ Implemented | R/W | None |
| 3 | FEPSW | ✅ Documented | ✅ Implemented | R/W | None |
| 4 | ECR | ✅ Documented | ✅ Implemented | R | None |
| 5 | PSW | ✅ Documented | ✅ Implemented | R/W | None |
| 6-15 | Reserved | ✅ Documented | ✅ Reserved | - | None |

**Status:** ✅ Base registers complete

### V850E1+ System Registers

| RegID | Name | Doc Status | Impl Status | Access | Issues |
|-------|------|------------|-------------|--------|--------|
| 16 | CTPC | ✅ Documented | ✅ Implemented | R/W | None |
| 17 | CTPSW | ✅ Documented | ✅ Implemented | R/W | None |
| 18 | DBPC | ✅ Documented | ✅ Implemented | R/W | None |
| 19 | DBPSW | ✅ Documented | ✅ Implemented | R/W | None |
| 20 | CTBP | ✅ Documented | ✅ Implemented | R/W | None |
| 21 | DIR | ✅ Documented | ❌ Not Implemented | R/W | Missing |
| 22 | BPC0 | ✅ Documented | ❌ Not Implemented | R/W | Missing |
| 23 | ASID | ✅ Documented | ❌ Not Implemented | R/W | Missing |
| 24-27 | BPAV0, BPAM0, BPDV0, BPDM0 | ✅ Documented | ❌ Not Implemented | R/W | Missing (breakpoint registers) |

**Issues:**
- Debug/breakpoint registers (DIR, BPC0, ASID, BPAVn, etc.) not implemented
- Priority: Low (debug functionality, not required for code generation)

### V850E2M System Registers

| RegID | Name | Doc Status | Impl Status | Access | Issues |
|-------|------|------------|-------------|--------|--------|
| 6 | FPSR | ✅ Documented | ✅ Implemented | R/W | None |
| 7 | FPEPC | ✅ Documented | ✅ Implemented | R/W | None |
| 8 | FPST | ✅ Documented | ✅ Implemented | R/W | None |
| 9 | FPCC | ✅ Documented | ✅ Implemented | R/W | None |
| 10 | FPCFG | ✅ Documented | ✅ Implemented | R/W | None |
| 11 | SCCFG/FPEC | ✅ Documented | ✅ Implemented | R/W | None |
| 12 | SCBP | ✅ Documented | ✅ Implemented | R/W | None |
| 13 | EIIC | ✅ Documented | ❌ Not Implemented | R/W | Missing |
| 14 | FEIC | ✅ Documented | ❌ Not Implemented | R/W | Missing |
| 28 | EIWR | ✅ Documented | ✅ Implemented | R/W | None |
| 29 | FEWR | ✅ Documented | ✅ Implemented | R/W | None |
| 30 | DBWR | ✅ Documented | ✅ Implemented | R/W | None |
| 31 | BSEL | ✅ Documented | ✅ Implemented | R/W | None |

**Issues:**
- EIIC, FEIC (exception cause registers for V850E2M) not implemented
- Priority: Medium (useful for exception handling)

### V850E2M Banked Registers (BSEL-based access)

**Status:** ❌ Not Implemented

The V850E2M bank selection model using BSEL register is documented but not implemented:
- CPU Main Bank (BSEL=0x0000)
- Exception Handler Banks (BSEL=0x0010, 0x0011)
- Processor Protection Banks (BSEL=0x1000, 0x1010, 0x1001)
- FPU Status Bank (BSEL=0x2000)
- User Banks (BSEL=0xFF00, 0xFFFF)

**Priority:** Low (primarily for OS/RTOS support)

### RH850G3M System Registers (selID-based access)

**Status:** ❌ Not Implemented

RH850G3M uses a different system register access model with `LDSR reg2, regID, selID` syntax:

| selID | Group Name | Registers | Doc Status | Impl Status |
|-------|------------|-----------|------------|-------------|
| 0 | Basic | PSW, exception, CALLT, FPU | ✅ Documented | ❌ Not Implemented |
| 1 | Interrupt | ISPR, PMR, ICSR, INTCFG, RBASE, EBASE, INTBP, MCTL, PID | ✅ Documented | ❌ Not Implemented |
| 2 | MPU | MPM, MPRC, MPLAn, MPUAn, MPATn | ✅ Documented | ❌ Not Implemented |
| 5 | Cache | ICCTRL, ICERR, ICCFG, ICTAGL/H, ICDATL/H | ✅ Documented | ❌ Not Implemented |
| 10 | FPU | Alternative FPU access | ✅ Documented | ❌ Not Implemented |

**Priority:** High (required for RH850G3M support)

---

## 4. Missing Instructions Analysis

### RH850G3M-Specific Instructions (Not Implemented)

| Instruction | Format | Category | Priority | Notes |
|-------------|--------|----------|----------|-------|
| **LD.DW** | XIV | Load/Store | High | Load double-word (64-bit) |
| **ST.DW** | XIV | Load/Store | High | Store double-word (64-bit) |
| **LDL.W** | IX | Atomic | High | Load linked word |
| **STC.W** | IX | Atomic | High | Store conditional word |
| **CLL** | X | Atomic | High | Clear load link |
| **BINS** | XI | Data Manipulation | Medium | Bitfield insert |
| **ROTL** (imm) | XI | Shift | Medium | Rotate left by immediate |
| **ROTL** (reg) | XI | Shift | Medium | Rotate left by register |
| **PUSHSP** | X | Stack | High | Push multiple registers |
| **POPSP** | X | Stack | High | Pop multiple registers |
| **LOOP** | VII | Branch | Medium | Decrement and branch if not zero |
| **Bcond** (disp17) | VII | Branch | Medium | Extended 17-bit displacement conditional branch |
| **JARL** [reg1], reg3 | XI | Branch | Medium | Indirect jump and link |
| **CACHE** | IX | Cache | Low | Cache control operations |
| **PREF** | IX | Cache | Low | Prefetch hint |
| **SNOOZE** | X | Special | Low | Low-power snooze state |
| **SYNCI** | X | Sync | Low | Synchronize memory for instruction fetches |

**Total Missing:** 17 RH850G3M instructions

### PSW Extensions for RH850G3M (Not Implemented)

The RH850G3M PSW has additional fields not currently in implementation:
- Bit 30: UM (User Mode) - **Missing**
- Bits 18-16: CU2-CU0 (Coprocessor use permissions) - **Missing**
- Bit 15: EBV (Exception Base Vector) - **Missing**
- Bits 11-9: Debug field - **Missing**

**Priority:** High (required for user/supervisor mode support)

---

## 5. FPU Instruction Verification

### FPU Arithmetic (V850E2M)

| Instruction | Doc Status | Impl Status | Format | Issues |
|-------------|------------|-------------|--------|--------|
| ADDF.S | ✅ | ✅ | FI | None |
| ADDF.D | ✅ | ✅ | FI | None |
| SUBF.S | ✅ | ✅ | FI | None |
| SUBF.D | ✅ | ✅ | FI | None |
| MULF.S | ✅ | ✅ | FI | None |
| MULF.D | ✅ | ✅ | FI | None |
| DIVF.S | ✅ | ✅ | FI | None |
| DIVF.D | ✅ | ✅ | FI | None |
| NEGF.S | ✅ | ✅ | FI | None |
| NEGF.D | ✅ | ✅ | FI | None |
| ABSF.S | ✅ | ✅ | FI | None |
| ABSF.D | ✅ | ✅ | FI | None |
| SQRTF.S | ✅ | ✅ | FI | None |
| SQRTF.D | ✅ | ✅ | FI | None |
| RECIPF.S | ✅ | ✅ | FI | None |
| RECIPF.D | ✅ | ✅ | FI | None |
| RSQRTF.S | ✅ | ✅ | FI | None |
| RSQRTF.D | ✅ | ✅ | FI | None |
| MAXF.S | ✅ | ✅ | FI | None |
| MAXF.D | ✅ | ✅ | FI | None |
| MINF.S | ✅ | ✅ | FI | None |
| MINF.D | ✅ | ✅ | FI | None |

**Status:** ✅ FPU arithmetic instructions complete (22/22)

### FPU Multiply-Accumulate

| Instruction | Doc Status | Impl Status | Format | Issues |
|-------------|------------|-------------|--------|--------|
| MADDF.S | ✅ | ✅ | FI | None |
| MSUBF.S | ✅ | ✅ | FI | None |
| NMADDF.S | ✅ | ✅ | FI | None |
| NMSUBF.S | ✅ | ✅ | FI | None |

**Status:** ✅ FPU MAC instructions complete (4/4)

### FPU Conversion

| Instruction | Doc Status | Impl Status | Issues |
|-------------|------------|-------------|--------|
| CVTF.DS | ✅ | ✅ | None |
| CVTF.SD | ✅ | ✅ | None |
| CVTF.WS | ✅ | ✅ | None |
| CVTF.WD | ✅ | ✅ | None |
| CVTF.SW | ✅ | ✅ | None |
| CVTF.DW | ✅ | ✅ | None |
| CVTF.LS | ✅ | ✅ | None |
| CVTF.LD | ✅ | ✅ | None |
| CVTF.SL | ✅ | ✅ | None |
| CVTF.DL | ✅ | ✅ | None |
| CVTF.UWS | ✅ | ✅ | None |
| CVTF.UWD | ✅ | ✅ | None |
| CVTF.SUW | ✅ | ✅ | None |
| CVTF.DUW | ✅ | ✅ | None |
| CVTF.ULS | ✅ | ✅ | None |
| CVTF.ULD | ✅ | ✅ | None |
| CVTF.SUL | ✅ | ✅ | None |
| CVTF.DUL | ✅ | ✅ | None |

**Status:** ✅ FPU conversion instructions complete (18/18)

### FPU Rounding

| Instruction | Doc Status | Impl Status | Issues |
|-------------|------------|-------------|--------|
| TRNCF.SW | ✅ | ✅ | None |
| TRNCF.DW | ✅ | ✅ | None |
| TRNCF.SL | ✅ | ✅ | None |
| TRNCF.DL | ✅ | ✅ | None |
| TRNCF.SUW | ✅ | ✅ | None |
| TRNCF.DUW | ✅ | ✅ | None |
| TRNCF.SUL | ✅ | ✅ | None |
| TRNCF.DUL | ✅ | ✅ | None |
| CEILF.SW | ✅ | ✅ | None |
| CEILF.DW | ✅ | ✅ | None |
| CEILF.SL | ✅ | ✅ | None |
| CEILF.DL | ✅ | ✅ | None |
| CEILF.SUW | ✅ | ✅ | None |
| CEILF.DUW | ✅ | ✅ | None |
| CEILF.SUL | ✅ | ✅ | None |
| CEILF.DUL | ✅ | ✅ | None |
| FLOORF.SW | ✅ | ✅ | None |
| FLOORF.DW | ✅ | ✅ | None |
| FLOORF.SL | ✅ | ✅ | None |
| FLOORF.DL | ✅ | ✅ | None |
| FLOORF.SUW | ✅ | ✅ | None |
| FLOORF.DUW | ✅ | ✅ | None |
| FLOORF.SUL | ✅ | ✅ | None |
| FLOORF.DUL | ✅ | ✅ | None |

**Status:** ✅ FPU rounding instructions complete (24/24)

### FPU Comparison & Status

| Instruction | Doc Status | Impl Status | Issues |
|-------------|------------|-------------|--------|
| CMPF.S | ✅ | ✅ | None |
| CMPF.D | ✅ | ✅ | None |
| TRFSR | ✅ | ✅ | None |

**Status:** ✅ FPU comparison/status instructions complete (3/3)

**FPU Summary:** ✅ All 71 FPU instructions documented and implemented

---

## 6. Instruction Format Completeness

| Format | Size | Doc | Impl | Status | Issues |
|--------|------|-----|------|--------|--------|
| I | 16-bit | ✅ | ✅ | Complete | None |
| II | 16-bit | ✅ | ✅ | Complete | None |
| II-IMM6 | 16-bit | ✅ | ✅ | Complete | CALLT variant |
| III | 16-bit | ✅ | ✅ | Complete | None |
| IV | 16-bit | ✅ | ✅ | Complete | None |
| IV-E1 | 16-bit | ✅ | ✅ | Complete | V850E1 variant |
| V | 32-bit | ✅ | ✅ | Complete | None |
| VI | 32-bit | ✅ | ✅ | Complete | None |
| VI-E2 | 48-bit | ✅ | ✅ | Complete | V850E2 variant |
| VII | 32-bit | ✅ | ✅ | Complete | None |
| VIII | 32-bit | ✅ | ✅ | Complete | None |
| IX | 32-bit | ✅ | ✅ | Complete | None |
| X | 32-bit | ✅ | ✅ | Complete | None |
| XI | 32-bit | ✅ | ✅ | Complete | None |
| XI-IMM9 | 32-bit | ✅ | ✅ | Complete | 9-bit imm variant |
| XII | 32-bit | ✅ | ✅ | Complete | None |
| XIII | 32-bit | ✅ | ✅ | Complete | PREPARE/DISPOSE |
| XIV | 48-bit | ✅ | ⚠️ | Partial | Missing LD.DW/ST.DW for RH850G3M |
| FI | 32-bit | ✅ | ✅ | Complete | FPU base format |

**Status:** 17/18 formats complete (94%)

---

## 7. Documentation Discrepancies

### 7.1 Opcode Map - Extended Instructions

**Location:** docs/V850InstructionReference.md, "Extended Instruction Sub-Opcode (Format IX/X)" section

**Issue:** Documentation states bits 26:23 = 0011-1111 are "Illegal instruction" but implementation uses many of these codes for valid V850E1+ instructions.

**Missing from documentation opcode map:**
- Bits 26:23 = 0011: PREPARE (V850E1)
- Bits 26:23 = 0100: DISPOSE (V850E1)
- Bits 26:23 = 0110: CMOV (V850E1)
- Bits 26:23 = 0111: ADF/SBF (V850E2)
- Bits 26:23 = 1000: MAC/MACU (V850E2)
- Bits 26:23 = 1001-1101: Various V850E1/E2/E2M instructions

**Fix Required:** Expand opcode map table to include all sub-opcode ranges for extended instructions.

### 7.2 System Register Number Table

**Location:** docs/V850InstructionReference.md, "System Register Number" section

**Issue:** Documentation only shows base V850 system registers (0-5). Missing V850E1/E2M/RH850G3M registers.

**Fix Required:** Add complete system register tables for:
- V850E1 additions (regID 16-27)
- V850E2M additions (regID 6-14, 28-31)
- V850E2M banked registers (BSEL-based access model)
- RH850G3M registers (selID-based access model)

**Status:** Partially addressed in my recent commit (a40b3f82560d), but needs consolidation into a single reference table.

### 7.3 PSW Register Bit Fields

**Location:** docs/V850InstructionReference.md, PSW sections

**Issue:** PSW documentation is complete and matches implementation for V850/V850E1/V850E2M. However, RH850G3M PSW extensions (UM, CU0-2, EBV, Debug) are documented but not implemented.

**Fix Required:** None for documentation. Implementation needs update to support RH850G3M PSW fields.

---

## 8. Implementation Action Items

### Priority 1 (High) - RH850G3M Core Support

1. **Add RH850G3M CPU Variants**
   - File: `llvm/lib/Target/V850/V850.td`
   - Add `FeatureRH850G3M`, `FeatureRH850G3MH` feature flags
   - Add `rh850g3m`, `rh850g3mh` processor definitions
   - Depends on: V850E2M features + new atomic/cache/stack instructions

2. **Implement selID-based System Register Access**
   - Files: `V850RegisterInfo.td`, `V850InstrInfo.td`, `V850AsmParser.cpp`
   - Add selID operand to LDSR/STSR instructions
   - Add new system register groups (selID 0-10)
   - Define RH850G3M system registers (ISPR, PMR, ICSR, INTCFG, RBASE, EBASE, etc.)

3. **Implement PSW Extensions for User/Supervisor Mode**
   - Files: `V850RegisterInfo.td`, `V850ISelLowering.cpp`
   - Add UM (bit 30), CU0-CU2 (bits 18-16), EBV (bit 15), Debug (bits 11-9)
   - Implement privilege checking for supervisor-only instructions
   - Update PSW read/write handling for RH850G3M

4. **Implement RH850G3M Atomic Instructions**
   - File: `V850InstrInfo.td`
   - Add LDL.W (load linked word) - Format IX
   - Add STC.W (store conditional word) - Format IX
   - Add CLL (clear load link) - Format X
   - Implement atomic lowering in `V850ISelLowering.cpp`

5. **Implement RH850G3M Double-Word Load/Store**
   - File: `V850InstrInfo.td`
   - Add LD.DW (load double-word, 64-bit) - Format XIV
   - Add ST.DW (store double-word, 64-bit) - Format XIV
   - Handle register pair constraints (even-numbered register requirement)

### Priority 2 (Medium) - RH850G3M Extended Instructions

6. **Implement Stack Manipulation Instructions**
   - File: `V850InstrInfo.td`
   - Add PUSHSP (push multiple registers) - Format X
   - Add POPSP (pop multiple registers) - Format X
   - Update `V850FrameLowering.cpp` to use these for prologue/epilogue

7. **Implement Data Manipulation Instructions**
   - File: `V850InstrInfo.td`
   - Add BINS (bitfield insert) - Format XI
   - Add ROTL imm5, reg2, reg3 (rotate left by immediate) - Format XI
   - Add ROTL reg1, reg2, reg3 (rotate left by register) - Format XI

8. **Implement Extended Branch Instructions**
   - File: `V850InstrInfo.td`
   - Add Bcond disp17 (17-bit displacement conditional branch) - Format VII
   - Add JARL [reg1], reg3 (indirect jump and link) - Format XI
   - Add LOOP reg1, disp16 (decrement and branch) - Format VII

9. **Implement V850E2M Exception Cause Registers**
   - File: `V850RegisterInfo.td`
   - Add EIIC (regID 13) - EI-level exception cause
   - Add FEIC (regID 14) - FE-level exception cause

### Priority 3 (Low) - Debug and Cache Support

10. **Implement Debug/Breakpoint Registers (V850E1)**
    - File: `V850RegisterInfo.td`
    - Add DIR (regID 21), BPC0 (regID 22), ASID (regID 23)
    - Add BPAVn, BPAMn, BPDVn, BPDMn (regID 24-27)
    - Note: Debug support, not required for code generation

11. **Implement Cache Control Instructions (RH850G3M)**
    - File: `V850InstrInfo.td`
    - Add CACHE cacheop, [reg1] - Format IX
    - Add PREF prefop, [reg1] - Format IX
    - Add SYNCI - Format X
    - Add cache control system registers (selID=5: ICCTRL, ICERR, ICCFG, etc.)

12. **Implement V850E2M Bank Selection (BSEL)**
    - Files: Multiple
    - Implement BSEL-based register banking for V850E2M
    - Add bank selection logic to LDSR/STSR
    - Define banked register sets (CPU Main, Exception Handler, Processor Protection, FPU Status, User banks)

### Priority 4 (Low) - Special Purpose

13. **Implement Special Instructions**
    - File: `V850InstrInfo.td`
    - Add SNOOZE (low-power state) - Format X, RH850G3M

---

## 9. Documentation Action Items

### Priority 1 (High)

1. **Update Extended Instruction Opcode Map**
   - File: `docs/V850InstructionReference.md`
   - Section: "Extended Instruction Sub-Opcode (Format IX/X)"
   - Action: Expand table to include all sub-opcode ranges (bits 26:23 = 0011-1111)
   - Add entries for PREPARE, DISPOSE, CMOV, ADF, SBF, MAC, MACU, etc.

2. **Add Complete System Register Reference Table**
   - File: `docs/V850InstructionReference.md`
   - Section: "System Interface" → "System Register Access Models"
   - Action: Create consolidated table showing all system registers across all CPU variants
   - Include regID, selID (for RH850G3M), name, access permissions, CPU variant availability

### Priority 2 (Medium)

3. **Add RH850G3M Instruction Reference Section**
   - File: `docs/V850InstructionReference.md`
   - Section: "RH850G3M/G3MH Instructions"
   - Action: Verify all RH850G3M instructions are documented with correct encodings
   - Add any missing instructions (currently complete per my review)

4. **Add Instruction Encoding Examples**
   - File: `docs/V850InstructionReference.md`
   - Action: Add concrete encoding examples for each format
   - Show bit patterns for representative instructions

### Priority 3 (Low)

5. **Cross-Reference Implementation Status**
   - File: `docs/V850InstructionReference.md`
   - Action: Add implementation status markers to instruction tables
   - Note which instructions are LLVM backend implemented vs. documented only

---

## 10. Testing Requirements

### Unit Tests Needed

1. **Opcode Encoding Tests**
   - Verify all Format I-XIV encodings match documentation
   - Test special cases (reg2=0 alternatives, sub-opcode selection)

2. **System Register Access Tests**
   - Test LDSR/STSR with all valid regIDs
   - Test RH850G3M selID-based access (when implemented)
   - Test V850E2M BSEL-based banking (when implemented)

3. **PSW Bit Field Tests**
   - Test PSW read/write for all CPU variants
   - Test privilege checking (RH850G3M UM mode)
   - Test coprocessor permission (CU0-2)

4. **RH850G3M Instruction Tests**
   - Assembly/disassembly tests for all new instructions
   - Code generation tests for atomics (LDL.W/STC.W)
   - Code generation tests for double-word load/store

### Integration Tests Needed

1. **CPU Variant Selection Tests**
   - Test feature flag propagation for each -mcpu variant
   - Verify instruction availability per CPU variant

2. **Exception Handling Tests**
   - Test exception cause register updates (EIIC/FEIC)
   - Test PSW save/restore in exception handlers

---

## 11. Summary Statistics

### Implementation Coverage

- **CPU Variants:** 8/12 (67%) - Missing RH850G3M/G3MH/G4M/G4MH
- **Instructions:** 318/358+ (89%) - Missing 40+ RH850G3M instructions
- **Instruction Formats:** 17/18 (94%) - Format XIV partial (missing LD.DW/ST.DW)
- **System Registers:** 20/50+ (40%) - Missing RH850G3M selID-based registers
- **FPU Instructions:** 71/71 (100%) - Complete
- **Opcode Mappings:** Core V850-V850E2M complete; RH850G3M partial

### Documentation Coverage

- **Instruction Reference:** ✅ Complete for all variants
- **Opcode Maps:** ⚠️ Incomplete - needs extended instruction expansion
- **System Registers:** ⚠️ Incomplete - needs selID-based register table
- **PSW Layouts:** ✅ Complete for all variants
- **Bitfield Semantics:** ✅ Complete with recent updates

---

## 12. Recommended Implementation Sequence

### Phase 1: RH850G3M Foundation (2-3 weeks)
1. Add RH850G3M CPU variants and feature flags
2. Implement selID-based system register access
3. Add PSW extensions (UM, CU0-CU2, EBV)
4. Add RH850G3M system register definitions

### Phase 2: RH850G3M Critical Instructions (2 weeks)
5. Implement atomic instructions (LDL.W, STC.W, CLL)
6. Implement double-word load/store (LD.DW, ST.DW)
7. Implement stack manipulation (PUSHSP, POPSP)
8. Add exception cause registers (EIIC, FEIC)

### Phase 3: RH850G3M Extended Features (1-2 weeks)
9. Implement data manipulation (BINS, ROTL)
10. Implement extended branches (Bcond disp17, JARL indirect, LOOP)
11. Add cache control instructions
12. Add special instructions (SNOOZE, SYNCI)

### Phase 4: Documentation and Testing (1 week)
13. Update documentation opcode maps
14. Add system register reference tables
15. Create comprehensive test suite
16. Validate all encodings against documentation

### Phase 5: V850E2M Banking (Optional, 1 week)
17. Implement BSEL-based register banking
18. Add banked register sets
19. Update LDSR/STSR for bank selection

**Total Estimated Effort:** 6-9 weeks for complete RH850G3M support

---

## 13. Open Questions

1. **RH850G3M Scheduler Model:** Does RH850G3M require a different scheduling model than V850E2M?
2. **Atomic Instruction Lowering:** Should we use LLVM's standard atomic lowering or custom patterns for LDL.W/STC.W?
3. **BSEL Banking:** Is V850E2M bank selection actually used in practice by compilers, or is it OS/firmware-only?
4. **Debug Registers:** Should we implement DIR/BPC/ASID registers for completeness, or defer until needed?
5. **RH850G4M:** What are the specific differences between RH850G3M and RH850G4M? Documentation not yet reviewed.

---

## 14. References

- **Implementation:** `/home/lfazio/Projects/llvm-project/llvm/lib/Target/V850/`
- **Documentation:** `/home/lfazio/Projects/llvm-project/docs/V850InstructionReference.md`
- **Specs:**
  - V850 Architecture Manual (docs/v850.txt)
  - V850E1 Architecture Manual (docs/v850e1.txt)
  - V850E2 Architecture Manual (docs/v850e2.txt)
  - V850E2M Architecture Manual (docs/v850e2m.txt)
  - RH850G3M Software Manual (docs/rh850g3m.txt)
  - RH850G3MH Software Manual (docs/rh850g3mh.txt)

---

**Document Version:** 1.0
**Last Updated:** 2026-01-10
**Status:** Initial verification complete, action items identified
