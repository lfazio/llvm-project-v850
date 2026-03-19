# Plan: RH850G4MH/G4MH2 Feature Implementation

This document tracks all features for the RH850G4MH and RH850G4MH2 CPU variants
and provides implementation steps for each.

## Overview

The RH850G4MH extends the RH850G3MH with:
- **Post-increment/decrement load/store** (16 instructions)
- **MPU bulk load/store** (LDM.MP, STM.MP — G4MH2 only)
- **CLIP instructions** (CLIP.B, CLIP.BU, CLIP.H, CLIP.HU — saturation clipping)
- **FXU 128-bit SIMD vector unit** (59 instructions, wreg0-wreg31)

The RH850G4MH2 further adds:
- **Virtualization** (HVTRAP, LDM.GSR, STM.GSR)
- **MPU load/store** (LDM.MP, STM.MP)
- **Guest system registers** (GMEIPC, GMEIPSW, GMFEPC, GMFEPSW, GMPSW, etc.)

## CPU Variant Hierarchy

```
V850E2M
  └── RH850G3M
        └── RH850G3MH
              └── RH850G4MH        ← this plan
                    └── RH850G4MH2  ← this plan (virtualization)
```

Each variant is a **strict superset** of the previous one.

### Register Architecture

The V850 family has **no dedicated FPU register file**. All scalar floating-point
instructions (ADDF.S, MULF.S, ADDF.D, etc.) operate on **general-purpose registers**
(r0-r31). The ISA documentation explicitly states: *"Floating-point operation register:
Uses general-purpose registers"* (V850E2M manual). Single-precision (f32) values use
individual GPRs; double-precision (f64) values use even/odd GPR pairs (e.g., r6:r7).

The **FXU** (Extended Floating-point coprocessor, RH850G4MH only) is the **only unit
with a dedicated register file**: 32 × 128-bit vector registers (wreg0-wreg31), each
holding 4 × single-precision floats. FXU requires PSW.CU1 coprocessor enable bit.

**Current LLVM implementation** correctly models this:
- `FPR` register class: alias over GPRs (r0-r31) for f32
- `DPR` register class: even/odd GPR pairs (D6, D8, ..., D28) for f64
- `VGPR` register class: wreg0-wreg31 (to be added for FXU, Sprint 5)

---

## Current State Summary

### Already Implemented (inherited from G3M/G3MH)

| Category | Status | Details |
|----------|--------|---------|
| **G3M Instructions** | Complete | SYNCI, SNOOZE, CLL, LDL.W, STC.W, ROTL, PUSHSP, POPSP, LOOP, CACHE, PREF, BINS, LD.DW, ST.DW, Bcond disp17 |
| **G3M Builtins** | Complete | synci, snooze, cll, ldl_w, stc_w, cache, pref |
| **G3M Scheduling** | Complete | `V850SchedRH850G3M.td` |
| **Double-Precision FPU** | Complete | DPR class, f64 arith/convert/compare/load/store |

### Features to Implement

| Category | Priority | Effort | Status |
|----------|----------|--------|--------|
| **Infrastructure** | High | Low | **DONE** — Subtarget features, processor models, Clang macros |
| **Post-Increment Load/Store** | High | Medium | **DONE** — 16 instructions (LD.B/H/W/BU/HU + ST.B/H/W with [reg1]+/-) |
| **CLIP Instructions** | Medium | Low | **DONE** — CLIP.B, CLIP.BU, CLIP.H, CLIP.HU (4 instructions) |
| **MPU Load/Store** | Low | Low | **DONE** — LDM.MP, STM.MP (2 instructions, G4MH2 only) |
| **FXU SIMD** | Low | High | **DONE** — 59 vector instructions, VGPR register class, ISel patterns, TTI cost model |
| **Virtualization** | Low | Medium | **DONE** — HVTRAP, LDM.GSR, STM.GSR (G4MH2 only) |
| **G4MH Scheduling** | Low | Medium | **DONE** — V850SchedRH850G4MH.td with FXU latencies |
| **FXU Builtins** | Medium | Medium | TODO — 59 Clang builtins + LLVM intrinsics (see v850-intrinsics.md §18) |

---

## Phase 1: Infrastructure (Low Effort)

### 1.1 Subtarget Features

**File:** `llvm/lib/Target/V850/V850.td`

Add new features:
```tablegen
def FeatureRH850G4MH : SubtargetFeature<"rh850g4mh", "HasRH850G4MH", "true",
    "RH850G4MH extensions", [FeatureRH850G3MH]>;

def FeatureRH850G4MH2 : SubtargetFeature<"rh850g4mh2", "HasRH850G4MH2", "true",
    "RH850G4MH2 extensions (virtualization)", [FeatureRH850G4MH]>;
```

Add processor models:
```tablegen
def : ProcessorModel<"g4mh", RH850G3MModel, [FeatureRH850G4MH, FeatureFPU]>;
def : ProcessorModel<"g4mh2", RH850G3MModel, [FeatureRH850G4MH2, FeatureFPU]>;
```

Note: Reuse `RH850G3MModel` initially; Phase 6 adds a dedicated `RH850G4MHModel`.

### 1.2 Subtarget Predicates

**File:** `llvm/lib/Target/V850/V850Subtarget.h`

```cpp
bool HasRH850G4MH = false;
bool HasRH850G4MH2 = false;
```

**File:** `llvm/lib/Target/V850/V850InstrInfo.td` (or V850.td predicates)

```tablegen
def HasRH850G4MH  : Predicate<"Subtarget->hasRH850G4MH()">;
def HasRH850G4MH2 : Predicate<"Subtarget->hasRH850G4MH2()">;
```

### 1.3 Clang Support

**File:** `clang/lib/Basic/Targets/V850.cpp`

Add CPU names and preprocessor macros:
- `-mcpu=g4mh` → `__rh850__`, `__rh850g4mh__`
- `-mcpu=g4mh2` → `__rh850__`, `__rh850g4mh__`, `__rh850g4mh2__`

**File:** `clang/lib/Driver/ToolChains/V850.cpp`

Add `g4mh` and `g4mh2` to valid CPU list.
FPU is enabled by default for both.

### 1.4 Tests

- `clang/test/Driver/v850-g4mh.c` — Driver tests for `-mcpu=g4mh` / `-mcpu=g4mh2`
- `clang/test/Preprocessor/v850-g4mh.c` — Preprocessor macro tests

**Complexity:** Low
**Dependencies:** None

---

## Phase 2: Post-Increment Load/Store (Medium Effort, 16 Instructions)

### 2.1 Instruction Overview

RH850G4MH adds post-increment and post-decrement addressing modes to load/store
instructions. All use Format XI encoding (32-bit).

| Instruction | Operation | Increment | Opcode (bits[15:0]) | Opcode (bits[31:16]) |
|-------------|-----------|-----------|---------------------|----------------------|
| LD.B [reg1]+, reg3 | reg3 = sext(mem[reg1]); reg1 += 1 | +1 | `00010111111RRRRR` | `wwwww01101110000` |
| LD.B [reg1]-, reg3 | reg3 = sext(mem[reg1]); reg1 -= 1 | -1 | `00100111111RRRRR` | `wwwww01101110000` |
| LD.BU [reg1]+, reg3 | reg3 = zext(mem[reg1]); reg1 += 1 | +1 | `00011111111RRRRR` | `wwwww01101110000` |
| LD.BU [reg1]-, reg3 | reg3 = zext(mem[reg1]); reg1 -= 1 | -1 | `00101111111RRRRR` | `wwwww01101110000` |
| LD.H [reg1]+, reg3 | reg3 = sext(mem[reg1]); reg1 += 2 | +2 | `00010111111RRRRR` | `wwwww01101110100` |
| LD.H [reg1]-, reg3 | reg3 = sext(mem[reg1]); reg1 -= 2 | -2 | `00100111111RRRRR` | `wwwww01101110100` |
| LD.HU [reg1]+, reg3 | reg3 = zext(mem[reg1]); reg1 += 2 | +2 | `00011111111RRRRR` | `wwwww01101110100` |
| LD.HU [reg1]-, reg3 | reg3 = zext(mem[reg1]); reg1 -= 2 | -2 | `00101111111RRRRR` | `wwwww01101110100` |
| LD.W [reg1]+, reg3 | reg3 = mem[reg1]; reg1 += 4 | +4 | `00010111111RRRRR` | `wwwww01101111000` |
| LD.W [reg1]-, reg3 | reg3 = mem[reg1]; reg1 -= 4 | -4 | `00100111111RRRRR` | `wwwww01101111000` |
| ST.B reg3, [reg1]+ | mem[reg1] = reg3; reg1 += 1 | +1 | `00010111111RRRRR` | `wwwww01101110010` |
| ST.B reg3, [reg1]- | mem[reg1] = reg3; reg1 -= 1 | -1 | `00100111111RRRRR` | `wwwww01101110010` |
| ST.H reg3, [reg1]+ | mem[reg1] = reg3; reg1 += 2 | +2 | `00010111111RRRRR` | `wwwww01101110110` |
| ST.H reg3, [reg1]- | mem[reg1] = reg3; reg1 -= 2 | -2 | `00100111111RRRRR` | `wwwww01101110110` |
| ST.W reg3, [reg1]+ | mem[reg1] = reg3; reg1 += 4 | +4 | `00010111111RRRRR` | `wwwww01101111010` |
| ST.W reg3, [reg1]- | mem[reg1] = reg3; reg1 -= 4 | -4 | `00100111111RRRRR` | `wwwww01101111010` |

**Encoding pattern:**
- All instructions: bits[10:5] = `111111`, RRRRR = reg1, wwwww = reg3
- bits[15:11]: `00010` = post-increment (signed load), `00011` = post-increment (unsigned load),
  `00100` = post-decrement (signed load), `00101` = post-decrement (unsigned load)
- For stores: `00010` = post-increment, `00100` = post-decrement
- bits[20:16] distinguish data type: `10000` = byte, `10100` = halfword, `11000` = word,
  `10010` = store byte, `10110` = store halfword, `11010` = store word

**Constraint:** reg1 != reg3 (otherwise results are undefined for this CPU).

### 2.2 MC Layer Implementation

**Files:**
- `llvm/lib/Target/V850/V850InstrInfo.td` — Instruction definitions with `HasRH850G4MH` predicate
- `llvm/lib/Target/V850/V850InstrFormats.td` — Format XI variant for post-increment
- `llvm/lib/Target/V850/MCTargetDesc/V850MCCodeEmitter.cpp` — Encoding
- `llvm/lib/Target/V850/Disassembler/V850Disassembler.cpp` — Decoding
- `llvm/lib/Target/V850/AsmParser/V850AsmParser.cpp` — Parsing `[reg1]+` / `[reg1]-` syntax

**Instruction definition example:**
```tablegen
let Predicates = [HasRH850G4MH] in {
  def LDB_PostInc : V850InstXI<(outs GPR:$reg3, GPR:$wb),
                                (ins GPR:$reg1),
                                "ld.b\t[$reg1]+, $reg3",
                                []> {
    let Constraints = "$reg1 = $wb";
    let mayLoad = 1;
    let hasSideEffects = 0;
  }
}
```

### 2.3 CodeGen Implementation

**Files:**
- `llvm/lib/Target/V850/V850ISelLowering.cpp` — Set indexed load/store actions
- `llvm/lib/Target/V850/V850ISelDAGToDAG.cpp` — Match POST_INC/POST_DEC nodes

**ISelLowering:**
```cpp
if (Subtarget->hasRH850G4MH()) {
  setIndexedLoadAction(ISD::POST_INC, MVT::i8, Legal);
  setIndexedLoadAction(ISD::POST_INC, MVT::i16, Legal);
  setIndexedLoadAction(ISD::POST_INC, MVT::i32, Legal);
  setIndexedLoadAction(ISD::POST_DEC, MVT::i8, Legal);
  setIndexedLoadAction(ISD::POST_DEC, MVT::i16, Legal);
  setIndexedLoadAction(ISD::POST_DEC, MVT::i32, Legal);
  setIndexedStoreAction(ISD::POST_INC, MVT::i8, Legal);
  setIndexedStoreAction(ISD::POST_INC, MVT::i16, Legal);
  setIndexedStoreAction(ISD::POST_INC, MVT::i32, Legal);
  setIndexedStoreAction(ISD::POST_DEC, MVT::i8, Legal);
  setIndexedStoreAction(ISD::POST_DEC, MVT::i16, Legal);
  setIndexedStoreAction(ISD::POST_DEC, MVT::i32, Legal);
}
```

**DAGToDAG:** Match `ISD::LOAD` / `ISD::STORE` with `ISD::POST_INC` / `ISD::POST_DEC`
addressing mode and select the appropriate post-increment instruction.

### 2.4 Tests

- `llvm/test/MC/V850/g4mh/post-increment.s` — Assembly round-trip
- `llvm/test/MC/Disassembler/V850/g4mh-post-increment.txt` — Disassembly
- `llvm/test/CodeGen/V850/g4mh/post-increment-load.ll` — CodeGen for loads
- `llvm/test/CodeGen/V850/g4mh/post-increment-store.ll` — CodeGen for stores
- `llvm/test/CodeGen/V850/g4mh/post-increment-loop.ll` — Loop optimization with post-increment

**Complexity:** Medium
**Dependencies:** Phase 1 (infrastructure)

---

## Phase 3: CLIP Instructions (Low Effort, 4 Instructions)

### 3.1 Instruction Overview

RH850G4MH adds CLIP instructions for value saturation (clamping):

| Instruction | Operation | Format | Opcode |
|-------------|-----------|--------|--------|
| CLIP.B reg1, reg2 | reg2 = clip(reg1, -128, 127) | IX | `rrrrr111111RRRRR 0000000000010000` |
| CLIP.BU reg1, reg2 | reg2 = clip(reg1, 0, 255) | IX | `rrrrr111111RRRRR 0000000010010000` |
| CLIP.H reg1, reg2 | reg2 = clip(reg1, -32768, 32767) | IX | `rrrrr111111RRRRR 0000000000010010` |
| CLIP.HU reg1, reg2 | reg2 = clip(reg1, 0, 65535) | IX | `rrrrr111111RRRRR 0000000010010010` |

**Operation:** Saturates the value in reg1 to the specified range and stores in reg2.

**Flags affected:**
- CY: Set if saturation occurred (value was clamped)
- OV: 0
- S: Sign of result
- Z: Set if result is zero
- SAT: ORed with CY (sticky)

### 3.2 Implementation

**MC Layer:**
- Add instruction definitions in `V850InstrInfo.td` with `HasRH850G4MH` predicate
- Format IX encoding (same as other extended 2-register instructions)

**CodeGen:**
- Pattern match `smin(smax(x, -128), 127)` → CLIP.B
- Pattern match `umin(x, 255)` → CLIP.BU (with zero-lower-bound check)
- Pattern match `smin(smax(x, -32768), 32767)` → CLIP.H
- Pattern match `umin(x, 65535)` → CLIP.HU

**Builtins:**
```c
int __builtin_v850_clip_b(int x);     // Clip to signed byte range
unsigned __builtin_v850_clip_bu(int x); // Clip to unsigned byte range
int __builtin_v850_clip_h(int x);     // Clip to signed halfword range
unsigned __builtin_v850_clip_hu(int x); // Clip to unsigned halfword range
```

### 3.3 Tests

- `llvm/test/MC/V850/g4mh/clip.s` — Assembly round-trip
- `llvm/test/CodeGen/V850/g4mh/clip.ll` — CodeGen patterns
- `clang/test/CodeGen/V850/builtins-g4mh.c` — Clang builtins

**Complexity:** Low
**Dependencies:** Phase 1

---

## Phase 4: MPU Load/Store (Low Effort, 2 Instructions, G4MH2 Only)

### 4.1 Instruction Overview

| Instruction | Operands | Format | Opcode | Description |
|-------------|----------|--------|--------|-------------|
| LDM.MP | [reg1], eh-et | XI | `rrrrr111111RRRRR wwwww00101100110` | Load MPU entries (MPLA/MPUA/MPAT) from memory |
| STM.MP | eh-et, [reg1] | XI | `rrrrr111111RRRRR wwwww00101100100` | Store MPU entries to memory |

Where `rrrrr` = eh (start entry), `wwwww` = et (end entry), `RRRRR` = reg1 (base address).

**Operation (LDM.MP):**
- For each entry `cur` from `eh` to `et`:
  - MPLA[cur] = mem[addr]; addr += 4
  - MPUA[cur] = mem[addr]; addr += 4
  - MPAT[cur] = mem[addr]; addr += 4
- Address is word-aligned (lower 2 bits masked to 0)
- reg1 retains original value after execution
- SV privilege instruction (PIE exception if PSW.UM=1)

**Operation (STM.MP):**
- Reverse of LDM.MP: stores MPU entries to memory
- Same privilege requirements

### 4.2 Implementation

**MC Layer only** — these are privileged system instructions with no codegen patterns.

**Files:**
- `llvm/lib/Target/V850/V850InstrInfo.td` — Instruction definitions with `HasRH850G4MH2`
- Assembler/disassembler support for `eh-et` operand syntax

**Builtins:**
```c
void __builtin_v850_ldm_mp(void *addr, unsigned eh, unsigned et);
void __builtin_v850_stm_mp(unsigned eh, unsigned et, void *addr);
```

### 4.3 Tests

- `llvm/test/MC/V850/g4mh/mpu.s` — Assembly round-trip
- `llvm/test/MC/Disassembler/V850/g4mh-mpu.txt` — Disassembly

**Complexity:** Low
**Dependencies:** Phase 1

---

## Phase 5: FXU SIMD Vector Unit (High Effort, 59 Instructions)

### 5.1 Overview

The FXU (Floating-point eXtended Unit) provides 128-bit SIMD operations on
4 parallel single-precision floating-point values.

**Key features:**
- 32 dedicated 128-bit vector registers (wreg0-wreg31)
- Separate status register FXSR (independent from FPU's FPSR)
- Requires PSW.CU1=1 (Coprocessor 1 Use Permission)
- IEEE 754 compliant

### 5.2 Register Class

**File:** `llvm/lib/Target/V850/V850RegisterInfo.td`

```tablegen
// 128-bit vector register class
class VGPRReg<bits<5> Enc, string n> : V850Reg<n> {
  let HWEncoding = Enc;
}

foreach i = 0-31 in
  def WREG#i : VGPRReg<i, "wreg"#i>;

def VGPR : RegisterClass<"V850", [v4f32], 128,
    (add WREG0, WREG1, WREG2, ..., WREG31)>;
```

### 5.3 Instruction Categories (59 Total)

#### Vector Manipulation (3)

| Mnemonic | Operands | Description |
|----------|----------|-------------|
| MOVV.W4 | wreg2, wreg3 | Move vector register |
| FLPV.S4 | wreg1, wreg2, wreg3 | Flip (exchange) elements |
| SHFLV.W4 | imm12, wreg1, wreg2, wreg3 | Shuffle elements |

#### Vector Load/Store (8)

| Mnemonic | Operands | Description |
|----------|----------|-------------|
| LDV.W | disp16[reg1], wreg3 | Load single word to element |
| LDV.DW | disp16[reg1], wreg3 | Load double-word |
| LDV.QW | disp16[reg1], wreg3 | Load quad-word (full 128-bit) |
| LDVZ.H4 | disp16[reg1], wreg3 | Load 4 halfwords, zero-extend |
| STV.W | wreg3, disp16[reg1] | Store single word |
| STV.DW | wreg3, disp16[reg1] | Store double-word |
| STV.QW | wreg3, disp16[reg1] | Store quad-word |
| STVZ.H4 | wreg3, disp16[reg1] | Store 4 words truncated to halfwords |

#### Vector Arithmetic (11)

| Mnemonic | Operands | Description |
|----------|----------|-------------|
| ABSF.S4 | wreg2, wreg3 | Absolute value (4x) |
| NEGF.S4 | wreg2, wreg3 | Negate (4x) |
| ADDF.S4 | wreg1, wreg2, wreg3 | Add (4x) |
| SUBF.S4 | wreg1, wreg2, wreg3 | Subtract (4x) |
| MULF.S4 | wreg1, wreg2, wreg3 | Multiply (4x) |
| DIVF.S4 | wreg1, wreg2, wreg3 | Divide (4x) |
| MAXF.S4 | wreg1, wreg2, wreg3 | Maximum (4x) |
| MINF.S4 | wreg1, wreg2, wreg3 | Minimum (4x) |
| SQRTF.S4 | wreg2, wreg3 | Square root (4x) |
| RECIPF.S4 | wreg2, wreg3 | Reciprocal (4x) |
| RSQRTF.S4 | wreg2, wreg3 | Reciprocal square root (4x) |

#### Vector Fused Multiply-Add (4)

| Mnemonic | Operands | Description |
|----------|----------|-------------|
| FMAF.S4 | wreg1, wreg2, wreg3 | w3 = w2*w1 + w3 |
| FMSF.S4 | wreg1, wreg2, wreg3 | w3 = w2*w1 - w3 |
| FNMAF.S4 | wreg1, wreg2, wreg3 | w3 = -(w2*w1) + w3 |
| FNMSF.S4 | wreg1, wreg2, wreg3 | w3 = -(w2*w1) - w3 |

#### Compound Arithmetic (4)

| Mnemonic | Operands | Description |
|----------|----------|-------------|
| ADDSUBF.S4 | wreg1, wreg2, wreg3 | w3[3:2]=add, w3[1:0]=sub |
| ADDSUBNF.S4 | wreg1, wreg2, wreg3 | w3[3:2]=add, w3[1:0]=sub (negated) |
| SUBADDF.S4 | wreg1, wreg2, wreg3 | w3[3:2]=sub, w3[1:0]=add |
| SUBADDNF.S4 | wreg1, wreg2, wreg3 | w3[3:2]=sub, w3[1:0]=add (negated) |

#### Exchange Arithmetic (7)

| Mnemonic | Operands | Description |
|----------|----------|-------------|
| ADDXF.S4 | wreg1, wreg2, wreg3 | Add with element exchange |
| SUBXF.S4 | wreg1, wreg2, wreg3 | Subtract with element exchange |
| MULXF.S4 | wreg1, wreg2, wreg3 | Multiply with element exchange |
| ADDSUBXF.S4 | wreg1, wreg2, wreg3 | Add-sub with exchange |
| ADDSUBNXF.S4 | wreg1, wreg2, wreg3 | Add-sub negated with exchange |
| SUBADDXF.S4 | wreg1, wreg2, wreg3 | Sub-add with exchange |
| SUBADDNXF.S4 | wreg1, wreg2, wreg3 | Sub-add negated with exchange |

#### Reduction (5)

| Mnemonic | Operands | Description |
|----------|----------|-------------|
| ADDRF.S4 | wreg2, wreg3 | Reduction add (sum all 4 elements) |
| SUBRF.S4 | wreg2, wreg3 | Reduction subtract |
| MULRF.S4 | wreg2, wreg3 | Reduction multiply |
| MAXRF.S4 | wreg2, wreg3 | Reduction maximum |
| MINRF.S4 | wreg2, wreg3 | Reduction minimum |

#### Conversion (14)

| Mnemonic | Operands | Description |
|----------|----------|-------------|
| CVTF.HS4 | wreg2, wreg3 | Convert 4x half to 4x single |
| CVTF.SH4 | wreg2, wreg3 | Convert 4x single to 4x half |
| CVTF.SW4 | wreg2, wreg3 | Convert 4x single to 4x word (int) |
| CVTF.WS4 | wreg2, wreg3 | Convert 4x word (int) to 4x single |
| CVTF.SUW4 | wreg2, wreg3 | Convert 4x single to 4x unsigned word |
| CVTF.UWS4 | wreg2, wreg3 | Convert 4x unsigned word to 4x single |
| TRNCF.SW4 | wreg2, wreg3 | Truncate 4x single to 4x word |
| TRNCF.SUW4 | wreg2, wreg3 | Truncate 4x single to 4x unsigned word |
| CEILF.SW4 | wreg2, wreg3 | Ceiling 4x single to 4x word |
| CEILF.SUW4 | wreg2, wreg3 | Ceiling 4x single to 4x unsigned word |
| FLOORF.SW4 | wreg2, wreg3 | Floor 4x single to 4x word |
| FLOORF.SUW4 | wreg2, wreg3 | Floor 4x single to 4x unsigned word |
| ROUNDF.SW4 | wreg2, wreg3 | Round 4x single to 4x word |
| ROUNDF.SUW4 | wreg2, wreg3 | Round 4x single to 4x unsigned word |

#### Comparison (3)

| Mnemonic | Operands | Description |
|----------|----------|-------------|
| CMPF.S4 | fcond, wreg1, wreg2, wreg3 | Compare 4x single, store mask |
| CMOVF.W4 | fcond4, wreg1, wreg2, wreg3 | Conditional move based on FXSR |
| TRFSRV.W4 | imm3, wreg2 | Transfer FXU status to vector |

### 5.4 Implementation Plan

**Sub-phase 5a: Infrastructure**
1. Add VGPR register class (wreg0-wreg31) to `V850RegisterInfo.td`
2. Add new instruction format classes for FXU in `V850InstrFormats.td`:
   - `FormatM_2OP` (32-bit, 2-operand vector)
   - `FormatM_3OP` (32-bit, 3-operand vector)
   - `FormatM_4OP` (48-bit, 4-operand vector)
   - `FormatM_MEM` (48-bit, memory operations)
3. Create `V850InstrFXU.td` for all 59 FXU instructions

**Sub-phase 5b: MC Layer**
4. Add instruction definitions with `HasRH850G4MH` predicate
5. Implement encoding in `V850MCCodeEmitter.cpp`
6. Implement decoding in `V850Disassembler.cpp` (new decoder namespace `"RH850G4MH"`)
7. Add assembler support for wreg operands in `V850AsmParser.cpp`

**Sub-phase 5c: Builtins**
8. Add Clang builtins for all 59 instructions in `BuiltinsV850.def`
9. Add LLVM intrinsics in `IntrinsicsV850.td`
10. Implement CodeGen in `V850.cpp` (Clang) and ISel patterns

**Sub-phase 5d: Auto-Vectorization [DONE]**
11. ~~Add `TargetTransformInfo` hooks for vectorization cost model~~ ✓
12. ~~Register VGPR as a legal vector register class~~ ✓
13. ~~Add vector type legalization (v4f32)~~ ✓
14. ~~ISel patterns for 12 v4f32 operations + LDV_QW/STV_QW load/store~~ ✓
15. ~~Custom lowering for BUILD_VECTOR, EXTRACT_VECTOR_ELT, INSERT_VECTOR_ELT, SCALAR_TO_VECTOR~~ ✓
16. ~~TTI cost model: getMemoryOpCost (align<16 → cost 100), getVectorInstrCost (cost 10), alignment enforcement~~ ✓

**Note:** Auto-vectorization of scalar `float*` loops is intentionally blocked by the TTI
cost model — the vectorizer sees `align 4` on individual float loads but FXU requires
`align 16`. Users must use explicit vector types (`v4sf*`) or builtins for SIMD. This is
standard practice for embedded SIMD targets with strict alignment requirements.

### 5.5 Tests

- `llvm/test/MC/V850/g4mh/fxu-arithmetic.s`
- `llvm/test/MC/V850/g4mh/fxu-load-store.s`
- `llvm/test/MC/V850/g4mh/fxu-manipulation.s`
- `llvm/test/MC/V850/g4mh/fxu-conversion.s`
- `llvm/test/MC/V850/g4mh/fxu-compare.s`
- `llvm/test/MC/Disassembler/V850/g4mh-fxu.txt`
- `clang/test/CodeGen/V850/builtins-fxu.c`

**Complexity:** High (new register class, 59 instructions, new encoding formats)
**Dependencies:** Phase 1

---

## Phase 6: Virtualization (Medium Effort, G4MH2 Only)

### 6.1 Instruction Overview

| Instruction | Operands | Format | Opcode | Description |
|-------------|----------|--------|--------|-------------|
| HVTRAP | vector5 | X | `00000111111vvvvv 0000000100010000` | Hypervisor EI-level trap |
| LDM.GSR | [reg1] | X | `00000111111RRRRR 1001100101100000` | Load multiple guest system registers |
| STM.GSR | [reg1] | X | `00000111111RRRRR 1001000101100000` | Store multiple guest system registers |

**HVTRAP:**
- Saves PC+4 to HMEIPC, HMPSW to HMEIPSW, PSWH to EIPSWH
- Stores vector5 as cause code in HMEIIC
- Clears PSWH.GM (enter host mode)
- SV privilege, requires HVCFG.HVE=1

**LDM.GSR:**
- Loads pre-defined guest system registers from memory starting at reg1
- Word-aligned access, reg1 unchanged after execution
- HV privilege instruction

**STM.GSR:**
- Stores pre-defined guest system registers to memory starting at reg1
- Word-aligned access, reg1 unchanged after execution
- HV privilege instruction

### 6.2 Guest System Registers

G4MH2 adds guest-mode system registers (accessed via LDSR/STSR with bank selection):

| Register | Bank | regID | Description |
|----------|------|-------|-------------|
| GMEIPC | 0 | 0 | Guest EI saved PC |
| GMEIPSW | 0 | 1 | Guest EI saved PSW |
| GMFEPC | 0 | 2 | Guest FE saved PC |
| GMFEPSW | 0 | 3 | Guest FE saved PSW |
| GMPSW | 0 | 5 | Guest PSW |
| GMEIIC | 0 | 13 | Guest EI exception cause |
| GMFEIC | 0 | 14 | Guest FE exception cause |
| GMSPID | 0 | 16 | Guest system protection ID |
| GMSPIDLIST | 0 | 17 | Guest SPID list |
| GMEBASE | 0 | 3 (grp 2) | Guest exception base address |
| GMINTBP | 0 | 4 (grp 2) | Guest interrupt base pointer |
| GMINTCFG | 0 | 13 (grp 2) | Guest interrupt configuration |
| GMPLMR | 0 | 14 (grp 2) | Guest priority level mask |
| HVCFG | 2 | 16 | Hypervisor configuration |
| HVTYPE | 2 | 17 | Hypervisor type |

### 6.3 Implementation

**MC Layer only** — these are privileged hypervisor instructions.

**Files:**
- `llvm/lib/Target/V850/V850InstrInfo.td` — Instruction definitions with `HasRH850G4MH2`
- `llvm/lib/Target/V850/V850RegisterInfo.td` — Guest system register definitions

**Builtins:**
```c
void __builtin_v850_hvtrap(unsigned vector);
void __builtin_v850_ldm_gsr(void *addr);
void __builtin_v850_stm_gsr(void *addr);
```

### 6.4 Tests

- `llvm/test/MC/V850/g4mh/virtualization.s` — Assembly round-trip
- `clang/test/CodeGen/V850/builtins-g4mh-virt.c` — Builtins

**Complexity:** Medium
**Dependencies:** Phase 1

---

## Phase 7: G4MH Scheduling Model (Medium Effort)

### 7.1 Overview

Create `V850SchedRH850G4MH.td` derived from `RH850G3MModel` with G4MH-specific timings.

**Key timing differences from G3M (from docs/rh850g4mh.txt):**

| Instruction | G3M Cycles | G4MH Cycles | Notes |
|-------------|-----------|------------|-------|
| LD.B/H/W [reg1]+/- | N/A | 1 cycle (pipe), 3+1 (hazard) | New instruction |
| ST.B/H/W [reg1]+/- | N/A | 1 cycle (pipe) | New instruction |
| CLIP.B/BU/H/HU | N/A | 1 cycle | New instruction |
| LDM.MP | N/A | N+8 cycles | N = number of entries |
| STM.MP | N/A | N+2 cycles | N = number of entries |

**FXU instruction timings:**

| Category | Latency | Throughput |
|----------|---------|------------|
| ADDF.S4, SUBF.S4 | 4 cycles | 1/cycle |
| MULF.S4 | 4 cycles | 1/cycle |
| DIVF.S4 | 14 cycles | 14 cycles |
| SQRTF.S4 | 14 cycles | 14 cycles |
| RECIPF.S4 | 10 cycles | 10 cycles |
| RSQRTF.S4 | 14 cycles | 14 cycles |
| FMAF.S4 | 4 cycles | 1/cycle |
| CVTF.* | 4 cycles | 1/cycle |
| LDV.QW | 2 cycles | 1/cycle |
| STV.QW | 1 cycle | 1/cycle |

### 7.2 Implementation

**File:** `llvm/lib/Target/V850/V850SchedRH850G4MH.td`

Derive from G3M model, add:
- WritePostIncLD / WritePostIncST for post-increment load/store
- WriteCLIP for CLIP instructions
- WriteFXU_ALU / WriteFXU_MUL / WriteFXU_DIV / WriteFXU_SQRT for FXU
- WriteFXU_MEM for FXU load/store
- WriteLDM_MP / WriteSTM_MP for MPU operations

**File:** `llvm/lib/Target/V850/V850.td`

Update processor model:
```tablegen
def : ProcessorModel<"g4mh", RH850G4MHModel, [FeatureRH850G4MH, FeatureFPU]>;
```

### 7.3 Tests

- `llvm/test/CodeGen/V850/sched-g4mh.ll`
- `llvm/test/CodeGen/V850/sched-g4mh-fxu.ll`

**Complexity:** Medium
**Dependencies:** Phases 2-5 (or at least Phase 2)

---

## Implementation Order

### Sprint 1: Infrastructure [DONE]
1. [1.1] ~~Add FeatureRH850G4MH/G4MH2, processor models~~ ✓
2. [1.2] ~~Add HasRH850G4MH/HasRH850G4MH2 predicates~~ ✓
3. [1.3] ~~Clang support (CPU names, macros)~~ ✓
4. [1.4] ~~Tests~~ ✓

### Sprint 2: Post-Increment Load/Store [DONE]
5. [2.2] ~~MC layer — instruction definitions, encoding, decoding~~ ✓
6. [2.2] ~~AsmParser — `[reg1]+` / `[reg1]-` syntax~~ ✓
7. [2.3] ~~CodeGen — setIndexedLoadAction/setIndexedStoreAction, getPostIndexedAddressParts(), ISel in DAGToDAG~~ ✓
8. [2.4] ~~MC tests~~ ✓ / ~~CodeGen tests~~ ✓

### Sprint 3: CLIP Instructions [DONE]
9. [3.2] ~~MC layer — instruction definitions~~ ✓
10. [3.2] ~~CodeGen — ISel patterns for saturation~~ ✓
11. [3.2] ~~Clang builtins~~ ✓
12. [3.3] ~~Tests~~ ✓

### Sprint 4: MPU Instructions [DONE]
13. [4.2] ~~MC layer — LDM.MP, STM.MP definitions~~ ✓
14. [4.2] Builtins (deferred — privileged instructions, low priority)
15. [4.3] ~~Tests~~ ✓

### Sprint 5: FXU Vector Unit [DONE]
16. [5.4a] ~~VGPR register class (wreg0-wreg31, 128-bit, v4f32)~~ ✓
17. [5.4a] ~~Instruction format classes (FormatM_2OP, 3OP, 4OP, Imm12, D)~~ ✓
18. [5.4b] ~~All 59 FXU instructions (MC layer: assembly, encoding, disassembly)~~ ✓
19. [5.4c] Builtins for FXU operations (deferred — 59 intrinsics, see v850-intrinsics.md §18)
20. [5.4d] ~~Auto-vectorization: v4f32 ISel patterns (12 ops + LDV_QW/STV_QW)~~ ✓
21. [5.4d] ~~Auto-vectorization: TTI cost model (getMemoryOpCost, getVectorInstrCost, alignment)~~ ✓
22. [5.4d] ~~Auto-vectorization: custom lowering (BUILD_VECTOR, EXTRACT/INSERT via stack)~~ ✓
23. [5.5] ~~Tests (10 MC test files + 2 CodeGen tests: fxu-vector-ops.ll, fxu-no-vectorize-unaligned.ll)~~ ✓

### Sprint 6: Virtualization [DONE]
21. [6.3] ~~HVTRAP, LDM.GSR, STM.GSR instructions~~ ✓
22. [6.3] Guest system register definitions (deferred — needs register bank support)
23. [6.3] Builtins (deferred — privileged instructions, low priority)
24. [6.4] ~~Tests~~ ✓

### Sprint 7: Scheduling Model [DONE]
25. [7.2] ~~Create V850SchedRH850G4MH.td~~ ✓
26. [7.3] ~~Tests (all 261 MC + 152 CodeGen pass, no regressions)~~ ✓

---

## Verification

For each sprint:
1. `ninja -C build-v850 V850CommonTableGen` — TableGen must succeed
2. `ninja -C build-v850` — Full build must succeed
3. `build-v850/bin/llvm-lit -j8 llvm/test/MC/V850/ llvm/test/MC/Disassembler/V850/ llvm/test/CodeGen/V850/` — All tests pass
4. New tests added for each feature

---

## Related Documents

- [V850 Instruction Reference](../docs/V850InstructionReference.md) — Full instruction set documentation
- [RH850G3M/G3MH Plan](plan-v850-g3m-g3mh.md) — Prerequisite G3M features
- [V850 Intrinsics Plan](v850-intrinsics.md) — Intrinsic catalog
- [V850 Optimisation Plan](v850-optimisation.md) — Optimization catalog
- [V850 Upstream Plan](v850-upstream-support.md) — Upstream patch series

## Source Documents

- `docs/rh850g4mh.txt` — RH850G4MH Software User's Manual (Rev.2.20, Dec 2023)
- `docs/rh850g4mh_virt.txt` — RH850G4MH Virtualization User's Manual (Rev.1.10, Jun 2021)

---

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2026-03-08 | 1.0 | Initial plan covering 7 phases: infrastructure, post-increment, CLIP, MPU, FXU, virtualization, scheduling |
| 2026-03-10 | 1.1 | Phase 1 (infrastructure) DONE, Phase 2 MC layer DONE (CodeGen TODO), Phase 3 (CLIP) DONE |
| 2026-03-10 | 1.2 | Phase 2 (post-increment) fully DONE: CodeGen added (setIndexedLoadAction, getPostIndexedAddressParts, ISel in DAGToDAG) |
| 2026-03-10 | 1.3 | Phase 4 (MPU) DONE: LDM.MP/STM.MP MC layer with FormatXI_MPU class, custom asm parsing, G4MH2 decoder namespace |
| 2026-03-10 | 1.4 | Phase 6 (Virtualization) DONE: HVTRAP, LDM.GSR, STM.GSR with FormatX_HVTRAP/FormatX_GSR classes, custom decoder |
| 2026-03-12 | 1.5 | Phase 5 (FXU) DONE: 59 SIMD instructions with VGPR register class, Format M formats, FXURH850G4MH decoder namespace, 10 test files |
| 2026-03-19 | 1.7 | Phase 5d (Auto-Vectorization) DONE: v4f32 ISel patterns for 12 ops + LDV_QW/STV_QW, TTI cost model (getMemoryOpCost align<16 → cost 100, getVectorInstrCost cost 10), custom lowering (BUILD_VECTOR, EXTRACT/INSERT via stack), tests (fxu-vector-ops.ll, fxu-no-vectorize-unaligned.ll). Sprint 5 fully complete. |
| 2026-03-12 | 1.6 | Phase 7 (Scheduling) DONE: V850SchedRH850G4MH.td with FXU/post-inc/CLIP/MPU/virtualization timings, G4MH processor model updated |
