# V850 Compiler Builtins Implementation Plan

This document tracks the implementation of V850-specific compiler builtins and intrinsics in LLVM/Clang.

## Current Implementation Status

### LLVM Backend - Implemented

| Category | Instructions | Intrinsics | Patterns | Status |
|----------|-------------|------------|----------|--------|
| **Atomic Bit Ops** | SET1, CLR1, NOT1, TST1 | `int_v850_set1/clr1/not1/tst1` | Yes | ✅ Complete |
| **Byte/Word Swap** | BSW, BSH, HSW | `int_v850_hsw/bsh` | `bswap` | ✅ Complete |
| **Bit Search** | SCH1L, SCH1R, SCH0L, SCH0R | — | `ctlz/cttz` | ✅ Complete |
| **CAXI** | CAXI | — | `atomic_cmp_swap` | ✅ Complete |
| **FPU Registers** | BSEL banking | 12 intrinsics | Yes | ✅ Complete |

### LLVM Backend - Partially Implemented

| Category | Instructions | Missing | Status |
|----------|-------------|---------|--------|
| **Saturating Arith** | SATADD, SATSUB, SATSUBR, SATADD_3, SATSUB_3 | `saddsat`/`ssubsat` patterns | ✅ Complete |
| **Memory Barriers** | SYNCP, SYNCM, SYNCE | Intrinsics, `fence` patterns | ✅ Complete |
| **Interrupt Control** | DI, EI | Intrinsics | ✅ Complete |
| **System Registers** | LDSR, STSR | Generic intrinsics | ✅ Complete |
| **MAC Operations** | MAC, MACU | Intrinsics | ✅ Complete |

### Clang Frontend - Implemented

| Component | Status |
|-----------|--------|
| `BuiltinsV850.def` | ✅ Complete |
| `CGBuiltin` V850 | ✅ Complete |
| User-facing builtins | ✅ Complete |
| Sema feature checking | ✅ Complete |

---

## Phase A: Complete LLVM Backend Patterns

### A.1 Saturating Arithmetic Patterns

**Status:** ✅ Complete (patterns already existed)

**Goal:** Map LLVM's `saddsat`/`ssubsat` intrinsics to V850 SATADD/SATSUB instructions.

**Files:**
- `llvm/lib/Target/V850/V850InstrInfo.td`

**Patterns to add:**
```tablegen
// Signed saturating add/sub
def : Pat<(saddsat GPR:$a, GPR:$b), (SATADD GPR:$b, GPR:$a)>;
def : Pat<(ssubsat GPR:$a, GPR:$b), (SATSUB GPR:$b, GPR:$a)>;
```

**Tests:**
- `llvm/test/CodeGen/V850/saturating-arith.ll`

---

### A.2 Memory Barrier Intrinsics and Patterns

**Status:** ✅ Complete

**Goal:** Add intrinsics for SYNCP/SYNCM/SYNCE and map `atomic_fence` to appropriate instructions.

**Files:**
- `llvm/include/llvm/IR/IntrinsicsV850.td`
- `llvm/lib/Target/V850/V850InstrInfo.td`
- `llvm/lib/Target/V850/V850ISelLowering.cpp`

**Intrinsics:**
```tablegen
def int_v850_syncp : Intrinsic<[], [], [IntrNoMem, IntrHasSideEffects]>;
def int_v850_syncm : Intrinsic<[], [], [IntrNoMem, IntrHasSideEffects]>;
def int_v850_synce : Intrinsic<[], [], [IntrNoMem, IntrHasSideEffects]>;
```

**Fence mapping:**
- `__sync_synchronize()` → SYNCP
- `__atomic_thread_fence(__ATOMIC_SEQ_CST)` → SYNCP
- `__atomic_thread_fence(__ATOMIC_ACQUIRE/RELEASE)` → SYNCM

**Tests:**
- `llvm/test/CodeGen/V850/memory-barriers.ll`

---

### A.3 Interrupt Control Intrinsics

**Status:** ✅ Complete

**Goal:** Add intrinsics for DI/EI instructions.

**Files:**
- `llvm/include/llvm/IR/IntrinsicsV850.td`
- `llvm/lib/Target/V850/V850InstrInfo.td`

**Intrinsics:**
```tablegen
def int_v850_di : Intrinsic<[], [], [IntrNoMem, IntrHasSideEffects]>;
def int_v850_ei : Intrinsic<[], [], [IntrNoMem, IntrHasSideEffects]>;
```

**Tests:**
- `llvm/test/CodeGen/V850/interrupt-control.ll`

---

### A.4 Generic LDSR/STSR Intrinsics

**Status:** ✅ Complete

**Goal:** Add generic intrinsics for system register access.

**Files:**
- `llvm/include/llvm/IR/IntrinsicsV850.td`
- `llvm/lib/Target/V850/V850ISelLowering.cpp`

**Intrinsics:**
```tablegen
def int_v850_ldsr : Intrinsic<[], [llvm_i32_ty, llvm_i32_ty],
                              [IntrNoMem, IntrHasSideEffects]>;
def int_v850_stsr : Intrinsic<[llvm_i32_ty], [llvm_i32_ty],
                              [IntrNoMem, IntrHasSideEffects]>;
```

**Tests:**
- `llvm/test/CodeGen/V850/sysreg-intrinsics.ll`

---

### A.5 MAC/MACU Intrinsics

**Status:** ✅ Complete

**Goal:** Add intrinsics for multiply-accumulate operations.

**Files:**
- `llvm/include/llvm/IR/IntrinsicsV850.td`
- `llvm/lib/Target/V850/V850InstrInfo.td`

**Intrinsics (implemented):**
```tablegen
// MAC - Signed multiply-accumulate
// (i32, i32) @llvm.v850.mac(i32 %a, i32 %b, i32 %acc_hi, i32 %acc_lo)
// Returns: (result_hi, result_lo) = (acc_hi:acc_lo) + sext(a) * sext(b)
def int_v850_mac : Intrinsic<[llvm_i32_ty, llvm_i32_ty],
                             [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
                             [IntrNoMem]>;

// MACU - Unsigned multiply-accumulate
// (i32, i32) @llvm.v850.macu(i32 %a, i32 %b, i32 %acc_hi, i32 %acc_lo)
// Returns: (result_hi, result_lo) = (acc_hi:acc_lo) + zext(a) * zext(b)
def int_v850_macu : Intrinsic<[llvm_i32_ty, llvm_i32_ty],
                              [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
                              [IntrNoMem]>;
```

**Tests:**
- `llvm/test/CodeGen/V850/mac-intrinsics.ll` - Direct intrinsic tests
- `llvm/test/CodeGen/V850/mac.ll` - Pattern matching tests (sext/zext + mul + add)
- `llvm/test/MC/V850/insn/mac.s` - MC encoding test
- `llvm/test/MC/V850/insn/macu.s` - MC encoding test

---

## Phase B: Clang Builtins

### B.1 Create BuiltinsV850.def

**Status:** ✅ Complete

**File:** `clang/include/clang/Basic/BuiltinsV850.def`

**Implemented Builtins:**

| Category | Builtins | Feature |
|----------|----------|---------|
| **Base V850** | `di`, `ei`, `ldsr`, `stsr`, `satadd`, `satsub` | (none) |
| **V850E1+** | `set1`, `clr1`, `not1`, `tst1`, `hsw`, `bsh`, `mac`, `macu` | `v850e1` |
| **V850E2M+** | `syncp`, `syncm`, `synce` | `v850e2m` |
| **FPU** | `read/write_fpsr`, `read/write_fpepc`, `read/write_fpst`, `read/write_fpcc`, `read/write_fpcfg`, `read/write_fpec` | `v850fpu` |

---

### B.2 Implement CGBuiltin for V850

**Status:** ✅ Complete

**File:** `clang/lib/CodeGen/TargetBuiltins/V850.cpp`

Maps Clang builtins to LLVM intrinsics:
- Bit operations → `llvm.v850.set1/clr1/not1/tst1`
- Byte swap → `llvm.v850.hsw/bsh`
- Barriers → `llvm.v850.syncp/syncm/synce`
- Interrupts → `llvm.v850.di/ei`
- System registers → `llvm.v850.ldsr/stsr`
- Saturating arithmetic → `llvm.sadd.sat.i32/llvm.ssub.sat.i32`
- FPU registers → `llvm.v850.read/write.*`

---

### B.3 Register builtins in V850TargetInfo

**Status:** ✅ Complete

**Files:**
- `clang/lib/Basic/Targets/V850.cpp` - `getTargetBuiltins()` implementation
- `clang/lib/Basic/Targets/V850.h` - `hasFeature()` for feature checking
- `clang/include/clang/Basic/TargetBuiltins.h` - V850 namespace

**Tests:**
- `clang/test/CodeGen/V850/builtins.c` - CodeGen verification
- `clang/test/Sema/v850-builtins-v850e1.c` - V850E1 positive test
- `clang/test/Sema/v850-builtins-v850e2m.c` - V850E2M positive test
- `clang/test/Sema/v850-builtins-error.c` - Feature error tests

---

## Phase C: Optimizations

### C.1 Combine Patterns

**Status:** ✅ Complete

- `(x >> 16) | (x << 16)` → HSW instruction
- `(x << 16) | (x >> 16)` → HSW instruction (both orderings)
- Saturating add/sub → SATADD/SATSUB (via saddsat/ssubsat intrinsics)
- `bswap i32` → BSW instruction
- BSH and HSW intrinsics

**Tests:**
- `llvm/test/CodeGen/V850/byte-swap.ll` - HSW, BSW, BSH patterns
- `llvm/test/CodeGen/V850/saturating-arith.ll` - SATADD/SATSUB patterns
- `llvm/test/CodeGen/V850/saturating-arithmetic.ll` - Additional sat tests

### C.2 Atomic Operation Improvements

**Status:** ✅ Complete

- CAXI generates optimal code for `cmpxchg` (direct pattern match)
- Atomic RMW operations (add, sub, and, or, xor, xchg) expand to CAXI loops
- All atomic operations properly use SYNCP for memory barriers

**Tests:**
- `llvm/test/CodeGen/V850/atomic.ll` - CAXI and atomic RMW operations

### C.3 MAC Instruction Selection

**Status:** ✅ Complete

- Pattern for `(a * b) + c` in 64-bit accumulator context → MAC/MACU
- Implemented in `V850ISelLowering.cpp` via DAG combining
- Pattern: `(sext(a) * sext(b)) + acc` → MAC
- Pattern: `(zext(a) * zext(b)) + acc` → MACU

### C.4 SWITCH Instruction Support

**Status:** ✅ Complete (Intrinsic + Jump table lowering)

**Description:**
The V850E1+ SWITCH instruction provides efficient table-driven branching for switch/case statements.

**Instruction Format:**
```
SWITCH reg1    ; Jump with table look up
```

**Operation:**
```
adr = (PC + 2) + (GR[reg1] << 1)           ; Table entry address
PC = (PC + 2) + sign_extend(mem[adr]) << 1  ; Target = table_base + offset
```

**Generated Assembly Example:**
```asm
    ; switch(index) with inline jump table
    switch  r6
.LJTI0_0:
    .hword  (.LBB0_2 - .LJTI0_0) >> 1    ; Entry 0: offset to case 0
    .hword  (.LBB0_3 - .LJTI0_0) >> 1    ; Entry 1: offset to case 1
    .hword  (.LBB0_4 - .LJTI0_0) >> 1    ; Entry 2: offset to case 2
    ...
.LBB0_2:
    ; case 0 code
.LBB0_3:
    ; case 1 code
```

**Implementation Details:**

1. **A.6 SWITCH Intrinsic** ✅
   - `llvm.v850.switch` intrinsic for direct access
   - Pattern: `(int_v850_switch GPR:$index)` → `(SWITCH GPR:$index)`

2. **C.5 Jump Table Lowering** ✅
   - `BR_JT` set to `Custom` for V850E1+
   - `LowerBR_JT` creates `V850ISD::BR_JT` node
   - `SWITCH_JT` pseudo instruction matches `V850brjt` SDNode
   - `V850AsmPrinter` expands `SWITCH_JT` to `SWITCH` + inline jump table
   - `getJumpTableEncoding()` returns `EK_Inline` for V850E1+

**Files Modified:**
- `V850InstrInfo.td`: SWITCH_JT pseudo, V850brjt SDNode
- `V850ISelLowering.cpp`: LowerBR_JT, getJumpTableEncoding
- `V850AsmPrinter.cpp`: SWITCH_JT expansion with inline table emission

**Intrinsic Definition:**
```tablegen
// SWITCH - Jump with table look up
// void @llvm.v850.switch(i32 %index)
// Branches to table[index], where table immediately follows the instruction
def int_v850_switch : Intrinsic<[], [llvm_i32_ty],
                                [IntrHasSideEffects]>;
```

**Benefits:**
- Reduced code size for large switch statements
- Faster execution (single instruction vs comparison chain)
- Cycle timing: 5-5-5 (V850E1), 8-8-8 (V850E2M), 11-18 (RH850G3M+)

**Tests:**
- `llvm/test/CodeGen/V850/switch-intrinsic.ll` - Direct intrinsic usage
- `llvm/test/CodeGen/V850/jump-table.ll` - Automatic switch lowering

---

## Implementation Priority

| Priority | Task | Effort | Impact | Status |
|----------|------|--------|--------|--------|
| 1 | A.1 Saturating arithmetic patterns | Low | Medium | ✅ |
| 2 | A.2 Memory barrier intrinsics | Low | High (correctness) | ✅ |
| 3 | A.3 DI/EI intrinsics | Low | Medium | ✅ |
| 4 | B.1-B.3 Clang builtins | Medium | High (usability) | ✅ |
| 5 | A.4 Generic LDSR/STSR | Medium | Medium | ✅ |
| 6 | A.5 MAC intrinsics | Medium | Low | ✅ |
| 7 | C.1-C.3 Optimizations | Medium | Medium | ✅ |
| 8 | A.6 SWITCH intrinsic | Low | Low | ✅ |
| 9 | C.5 Jump table lowering (BR_JT) | Medium | Medium | ✅ |

---

## Progress Log

| Date | Task | Status |
|------|------|--------|
| 2026-01-11 | FPU BSEL banking intrinsics | ✅ Complete |
| 2026-01-11 | Plan updated with current status | ✅ Complete |
| 2026-01-11 | A.1 Saturating arithmetic (already implemented) | ✅ Complete |
| 2026-01-11 | A.2 Memory barrier intrinsics (syncp/syncm/synce) | ✅ Complete |
| 2026-01-11 | A.3 Interrupt control intrinsics (di/ei) | ✅ Complete |
| 2026-01-11 | A.4 Generic LDSR/STSR intrinsics | ✅ Complete |
| 2026-01-11 | A.5 MAC/MACU intrinsics with pattern matching | ✅ Complete |
| 2026-01-11 | C.3 MAC instruction selection (DAG combine) | ✅ Complete |
| 2026-01-11 | C.1 Combine patterns (HSW, BSW, SATADD/SATSUB) | ✅ Complete |
| 2026-01-11 | C.2 Atomic operations (CAXI, atomic RMW) | ✅ Complete |
| 2026-01-11 | A.6 SWITCH intrinsic (llvm.v850.switch) | ✅ Complete |
| 2026-01-12 | C.5 Jump table lowering (BR_JT → SWITCH_JT) | ✅ Complete |
| 2026-01-13 | B.1 BuiltinsV850.def with TARGET_BUILTIN feature checks | ✅ Complete |
| 2026-01-13 | B.2 CGBuiltin V850 implementation | ✅ Complete |
| 2026-01-13 | B.3 V850TargetInfo getTargetBuiltins() | ✅ Complete |
| 2026-01-13 | Clang Sema tests for feature checking | ✅ Complete |
| 2026-01-13 | Fix feature name mismatch (fpu → v850fpu) | ✅ Complete |
| 2026-01-13 | Add MAC/MACU builtins to Clang | ✅ Complete |

---

## References

- NEC V850E2M User's Manual (Architecture)
- Renesas RH850 Compiler User's Manual
- LLVM TargetIntrinsics documentation
- `docs/V850InstructionReference.md`
