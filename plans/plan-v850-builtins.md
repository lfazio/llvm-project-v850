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

### Clang Frontend - Not Implemented

| Component | Status |
|-----------|--------|
| `BuiltinsV850.def` | ❌ Missing |
| `CGBuiltin` V850 | ❌ Missing |
| User-facing builtins | ❌ Missing |

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

**Status:** ❌ Not started

**File:** `clang/include/clang/Basic/BuiltinsV850.def`

**Builtins:**
```c
// Atomic bit operations
BUILTIN(__builtin_v850_set1, "vv*Ui", "n")
BUILTIN(__builtin_v850_clr1, "vv*Ui", "n")
BUILTIN(__builtin_v850_not1, "vv*Ui", "n")
BUILTIN(__builtin_v850_tst1, "iv*Ui", "n")

// Byte/word swap
BUILTIN(__builtin_v850_hsw, "UiUi", "nc")
BUILTIN(__builtin_v850_bsh, "UiUi", "nc")

// Memory barriers
BUILTIN(__builtin_v850_syncp, "v", "n")
BUILTIN(__builtin_v850_syncm, "v", "n")
BUILTIN(__builtin_v850_synce, "v", "n")

// Interrupt control
BUILTIN(__builtin_v850_di, "v", "n")
BUILTIN(__builtin_v850_ei, "v", "n")

// System registers
BUILTIN(__builtin_v850_ldsr, "vUiUi", "n")
BUILTIN(__builtin_v850_stsr, "UiUi", "n")

// Saturating arithmetic
BUILTIN(__builtin_v850_satadd, "iii", "nc")
BUILTIN(__builtin_v850_satsub, "iii", "nc")

// FPU register access (via BSEL banking)
BUILTIN(__builtin_v850_read_fpsr, "Ui", "n")
BUILTIN(__builtin_v850_write_fpsr, "vUi", "n")
// ... other FPU registers
```

---

### B.2 Implement CGBuiltin for V850

**Status:** ❌ Not started

**File:** `clang/lib/CodeGen/TargetBuiltins/V850.cpp`

Map Clang builtins to LLVM intrinsics.

---

### B.3 Register builtins in V850TargetInfo

**Status:** ❌ Not started

**File:** `clang/lib/Basic/Targets/V850.cpp`

Add `getTargetBuiltins()` implementation.

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

---

## Implementation Priority

| Priority | Task | Effort | Impact |
|----------|------|--------|--------|
| 1 | A.1 Saturating arithmetic patterns | Low | Medium |
| 2 | A.2 Memory barrier intrinsics | Low | High (correctness) |
| 3 | A.3 DI/EI intrinsics | Low | Medium |
| 4 | B.1-B.3 Clang builtins | Medium | High (usability) |
| 5 | A.4 Generic LDSR/STSR | Medium | Medium |
| 6 | A.5 MAC intrinsics | Medium | Low |
| 7 | C.1-C.3 Optimizations | Medium | Medium |

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

---

## References

- NEC V850E2M User's Manual (Architecture)
- Renesas RH850 Compiler User's Manual
- LLVM TargetIntrinsics documentation
- `docs/V850InstructionReference.md`
