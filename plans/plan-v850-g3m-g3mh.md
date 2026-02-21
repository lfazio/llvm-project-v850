# Plan: RH850G3M/G3MH Complete Feature Implementation

This document tracks all missing features for the RH850G3M and RH850G3MH CPU variants
and provides implementation steps for each.

## Current State Summary

### Already Implemented

| Category | Status | Details |
|----------|--------|---------|
| **G3M Instructions (MC)** | 15/15 | SYNCI, SNOOZE, CLL, LDL.W, STC.W, ROTL, PUSHSP, POPSP, LOOP, CACHE, PREF, BINS, LD.DW, ST.DW, Bcond disp17 |
| **G3M Builtins** | 5/5 | synci, snooze, cll, ldl_w, stc_w |
| **G3M Scheduling** | Complete | `V850SchedRH850G3M.td` with all G3M timings |
| **ROTL Codegen** | Complete | ISel patterns for immediate and register forms |
| **Subtarget Features** | Complete | `FeatureRH850G3M`, `FeatureRH850G3MH` |
| **Processor Models** | Complete | `-mcpu=g3m`, `-mcpu=g3mh` |
| **Clang Macros** | Complete | `__rh850__`, `__rh850g3m__`, `__rh850g3mh__` |
| **Atomic Load/Store** | Complete | Custom lowering with SYNCP fences |
| **Atomic CmpXchg** | Complete | Via CAXI (V850E2M path) |
| **SysReg 10-bit Unified Encoding** | Complete | Unified LDSR/STSR with `(selID<<5)\|regID`, named banked regs, `ldsr r1, ebase` syntax |

### Missing Features

| Category | Priority | Missing Items |
|----------|----------|---------------|
| ~~**ISel Patterns**~~ | ~~High~~ | ~~LD.DW, ST.DW, BINS~~ DONE |
| ~~**Atomic Expansion**~~ | ~~High~~ | ~~atomicrmw via LDL.W/STC.W~~ DONE |
| ~~**Builtins**~~ | ~~Medium~~ | ~~CACHE, PREF, BINS, ROTL~~ DONE |
| ~~**System Registers**~~ | ~~Medium~~ | ~~G3M Groups 1-7~~ DONE (LDSR/STSR sel + named builtins) |
| ~~**Frame Optimization**~~ | ~~Medium~~ | ~~PUSHSP/POPSP for prologue/epilogue~~ DONE |
| ~~**SysReg Refactoring**~~ | ~~Medium~~ | ~~Replace pseudo register class with immediate operands~~ DONE (10-bit unified encoding) |
| **Double-Precision FPU CodeGen** | Medium | All f64 ops marked Expand→libcalls; no DREG register class; instructions exist in MC layer only |
| **LOOP instruction** | Low | Hardware loop codegen |
| **G3MH specifics** | Low | FPU precision changes, FPINT exception |
| **Post-increment** | Low | LD/ST with [reg1]+ addressing (**G4MH only**, not G3M/G3MH) |

---

## Phase 1: CodeGen Patterns (High Priority)

### 1.1 LD.DW / ST.DW 64-bit Load/Store Patterns

**Goal:** Auto-generate LD.DW/ST.DW for 64-bit memory operations instead of
two separate 32-bit loads/stores.

**Current State:** Instructions defined in `V850InstrInfo.td` with `[]` (no patterns).
LD.DW loads a register pair (even register); ST.DW stores a register pair.

**Implementation:**

1. **Define a register pair class** in `V850RegisterInfo.td`:
   - `GPRPair` class for even-odd register pairs (r0:r1, r2:r3, ..., r30:r31)
   - Add sub-register indices for even/odd halves

2. **Add ISel patterns** in `V850InstrInfo.td`:
   ```tablegen
   // 64-bit load
   def : Pat<(i64 (load (add GPR:$base, simm23:$disp))),
             (LD_DW GPR:$base, simm23:$disp)>,
         Requires<[HasRH850G3M]>;

   // 64-bit store
   def : Pat<(store i64:$val, (add GPR:$base, simm23:$disp)),
             (ST_DW i64:$val, GPR:$base, simm23:$disp)>,
         Requires<[HasRH850G3M]>;
   ```

3. **Update calling convention** to use register pairs for i64 arguments/returns.

4. **Tests:**
   - `llvm/test/CodeGen/V850/g3m-load-store-64.ll`

**Complexity:** Medium (register pairs are non-trivial)

**Files:**
- `llvm/lib/Target/V850/V850RegisterInfo.td` - Register pair class
- `llvm/lib/Target/V850/V850InstrInfo.td` - ISel patterns
- `llvm/lib/Target/V850/V850ISelLowering.cpp` - Type legalization for i64

---

### 1.2 BINS Bitfield Insert Pattern

**Goal:** Use BINS for bitfield insertion instead of shift/mask/or sequences.

**Current State:** Three encoding variants (BINS0, BINS1, BINS2) in MC layer,
no DAG patterns.

**Implementation:**

1. **Add DAG combine** in `V850ISelLowering.cpp`:
   - Match `(or (and dst, mask), (and (shl src, pos), mask))` → BINS
   - Match LLVM IR `insertvalue` or explicit bit manipulation patterns

2. **Add builtin** in `BuiltinsV850.def`:
   ```c
   unsigned int __builtin_v850_bins(unsigned int src, unsigned int dst,
                                    unsigned int pos, unsigned int width);
   ```

3. **Tests:**
   - `llvm/test/CodeGen/V850/g3m-bins.ll`
   - `clang/test/CodeGen/V850/builtins-g3m-bins.c`

**Complexity:** Medium (pattern matching for bitfield operations)

**Files:**
- `llvm/lib/Target/V850/V850ISelLowering.cpp` - DAG combine
- `llvm/lib/Target/V850/V850InstrInfo.td` - ISel patterns
- `clang/include/clang/Basic/BuiltinsV850.def` - Builtin
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp` - CodeGen
- `llvm/include/llvm/IR/IntrinsicsV850.td` - Intrinsic

---

### 1.3 Atomic RMW via LDL.W/STC.W

**Goal:** Use LDL.W/STC.W (load-linked/store-conditional) for atomic RMW operations
on G3M instead of CAXI (compare-and-exchange). LDL.W/STC.W is more efficient
for operations like atomic add, or, xor since it avoids the CAS retry overhead.

**Current State:** `shouldExpandAtomicRMWInIR()` returns `CmpXChg` for V850E2M+,
which expands atomicrmw to CAXI-based CAS loops. LDL.W/STC.W only accessible
via explicit intrinsics.

**Implementation:**

1. **Override `shouldExpandAtomicRMWInIR()`** for G3M:
   - Return `AtomicExpansionKind::LLSC` when `hasRH850G3M()` is true
   - Keep `CmpXChg` as fallback for V850E2M without G3M

2. **Implement `emitLoadLinked()` and `emitStoreConditional()`**:
   ```cpp
   Value *V850TargetLowering::emitLoadLinked(IRBuilderBase &Builder,
                                              Type *ValueTy, Value *Addr,
                                              AtomicOrdering Ord) const {
     // Emit LDL.W intrinsic
     Function *LDL = Intrinsic::getOrInsertDeclaration(
         Builder.GetInsertBlock()->getModule(), Intrinsic::v850_ldl_w);
     return Builder.CreateCall(LDL, {Addr});
   }

   Value *V850TargetLowering::emitStoreConditional(IRBuilderBase &Builder,
                                                    Value *Val, Value *Addr,
                                                    AtomicOrdering Ord) const {
     // Emit STC.W intrinsic, returns 1 on success
     Function *STC = Intrinsic::getOrInsertDeclaration(
         Builder.GetInsertBlock()->getModule(), Intrinsic::v850_stc_w);
     Value *Result = Builder.CreateCall(STC, {Addr, Val});
     // STC.W returns 1 on success, LLVM expects 0 on success
     return Builder.CreateXor(Result, ConstantInt::get(Result->getType(), 1));
   }
   ```

3. **Handle fence insertion** in `emitLeadingFence()` / `emitTrailingFence()`.

4. **Tests:**
   - `llvm/test/CodeGen/V850/g3m-atomic-rmw.ll`
   - `llvm/test/CodeGen/V850/g3m-cmpxchg.ll`

**Complexity:** Medium

**Files:**
- `llvm/lib/Target/V850/V850ISelLowering.cpp` - LLSC expansion
- `llvm/lib/Target/V850/V850ISelLowering.h` - Declarations
- `llvm/test/CodeGen/V850/g3m-atomic-rmw.ll` - Tests

**Note:** Need to verify STC.W return value semantics (1=success vs 0=success)
against the documentation. The LLVM AtomicExpandPass expects store-conditional
to return 0 on success.

---

## Phase 2: Builtins and Intrinsics (Medium Priority)

### 2.1 CACHE Builtin

**Goal:** Expose CACHE instruction via builtin for cache management.

```c
void __builtin_v850_cache(unsigned int cacheop, volatile void *addr);
```

**Cache Operations (cacheop values):**

| Value | Name | Description |
|-------|------|-------------|
| 0x00 | CHBII | Invalidate instruction cache line by address |
| 0x04 | CIBII | Invalidate instruction cache by index |
| 0x06 | CFALI | Flush and invalidate instruction cache line |
| 0x07 | CISTI | Store instruction cache tag by index |
| 0x0C | CILDI | Load instruction cache tag by index |

**Implementation:**

1. Add `BUILTIN(__builtin_v850_cache, "vUiv*", "n")` to `BuiltinsV850.def`
2. Add `@llvm.v850.cache(i32, ptr)` to `IntrinsicsV850.td`
3. Add pattern `(int_v850_cache imm:$op, GPR:$addr)` → `CACHE`
4. Add CodeGen in `V850.cpp`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def`
- `llvm/include/llvm/IR/IntrinsicsV850.td`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp`
- `llvm/lib/Target/V850/V850InstrInfo.td`

---

### 2.2 PREF Builtin

**Goal:** Expose PREF instruction for data/instruction prefetch.

```c
void __builtin_v850_pref(unsigned int prefop, volatile void *addr);
```

**Prefetch Operations (prefop values):**

| Value | Name | Description |
|-------|------|-------------|
| 0x00 | PREFI | Prefetch instruction cache line |

**Implementation:** Same pattern as CACHE builtin.

---

### 2.3 BINS Builtin

**Goal:** Expose BINS instruction for efficient bitfield insertion.

```c
unsigned int __builtin_v850_bins(unsigned int dst, unsigned int src,
                                 unsigned int pos, unsigned int width);
```

**Description:** Insert `width` bits from `src` starting at bit position `pos` into `dst`.

**Implementation:**
1. Add `TARGET_BUILTIN(__builtin_v850_bins, "UiUiUiIUiIUi", "nc", "rh850g3m")` to `BuiltinsV850.def`
2. Add intrinsic and CodeGen

---

### 2.4 ROTL Builtin

**Goal:** Expose ROTL instruction. Note: `__builtin_rotateleft32()` already works
via LLVM's fshl intrinsic, but a V850-specific builtin provides direct access.

```c
unsigned int __builtin_v850_rotl(unsigned int x, unsigned int count);
```

**Priority:** Low (existing `__builtin_rotateleft32` works on G3M)

---

## Phase 3: System Registers [DONE]

### 3.1 G3M System Register Groups

**Status:** Completed. G3M Groups 1 and 2 are implemented via the unified 10-bit
encoding (see Phase 4b). Groups 4-8 (cache, MPU) can be added to
`V850SystemOperands.td` without structural changes.

The G3M uses a group-based system register addressing scheme where registers
are identified by (regID, groupID) pairs. The current V850 backend supports
Group 0 (base) plus selected Group 1 and Group 2 registers.

**Group 0 (Base - Already Implemented):**
- EIPC(0,0), EIPSW(1,0), FEPC(2,0), FEPSW(3,0), PSW(5,0)
- FPSR(6,0), FPEPC(7,0), FPST(8,0), FPCC(9,0), FPCFG(10,0), FPEC(11,0)
- EIIC(13,0), FEIC(14,0), CTPC(16,0), CTPSW(17,0), CTBP(20,0)
- EIWR(28,0), FEWR(29,0)

**Group 1 - Machine Configuration (NEW):**

| Register | regID,group | Description | Priority |
|----------|-------------|-------------|----------|
| MCFG0 | 0,1 | Machine Configuration | Medium |
| RBASE | 2,1 | Reset Vector Base Address | Medium |
| EBASE | 3,1 | Exception Handler Vector Base | Medium |
| INTBP | 4,1 | Interrupt Handler Table Base | Medium |
| MCTL | 5,1 | Machine Control | Medium |
| PID | 6,1 | Processor ID | Low |
| FPIPR | 7,1 | FPI Exception Priority (deleted in G3MH) | Low |
| SCCFG | 11,1 | SYSCALL Configuration | Low |
| SCBP | 12,1 | SYSCALL Base Pointer | Medium |

**Group 2 - Thread/Interrupt Configuration (NEW):**

| Register | regID,group | Description | Priority |
|----------|-------------|-------------|----------|
| HTCFG0 | 0,2 | Thread Configuration (PEID) | Low |
| MEA | 6,2 | Memory Error Address | Medium |
| ASID | 7,2 | Address Space ID | Low |
| MEI | 8,2 | Memory Error Information | Medium |
| ISPR | 10,2 | Interrupt Priority Status | Medium |
| PMR | 11,2 | Interrupt Priority Mask | Medium |
| ICSR | 12,2 | Interrupt Control Status | Low |
| INTCFG | 13,2 | Interrupt Configuration | Low |

**Group 4 - Cache Control (NEW - G3MH with instruction cache):**

| Register | regID,group | Description | Priority |
|----------|-------------|-------------|----------|
| ICTAGL | 16,4 | Instruction Cache Tag Lo | Low |
| ICTAGH | 17,4 | Instruction Cache Tag Hi | Low |
| ICDATL | 18,4 | Instruction Cache Data Lo | Low |
| ICDATH | 19,4 | Instruction Cache Data Hi | Low |
| ICCTRL | 24,4 | Instruction Cache Control | Medium |
| ICCFG | 26,4 | Instruction Cache Configuration | Low |
| ICERR | 28,4 | Instruction Cache Error | Low |

**Groups 5-7 - MPU Protection (NEW):**

| Register | regID,group | Description | Priority |
|----------|-------------|-------------|----------|
| MPM | 0,5 | MPU Mode | Medium |
| MPRC | 1,5 | MPU Region Control | Medium |
| MPBRGN | 4,5 | MPU Base Region Number | Low |
| MPTRGN | 5,5 | MPU End Region Number | Low |
| MCA | 8,5 | MPU Check Address | Low |
| MCS | 9,5 | MPU Check Size | Low |
| MCC | 10,5 | MPU Check Command | Low |
| MCR | 11,5 | MPU Check Result | Low |
| MPLA0-15 | 0-15,6 | Protection Area Min Address | Low |
| MPUA0-15 | 0-15,7 | Protection Area Max Address | Low |
| MPAT0-15 | 0-15,8 | Protection Area Attributes | Low |

**Implementation:**

1. **Update LDSR/STSR encoding** in V850InstrInfo.td to support group specification:
   - G3M LDSR/STSR format: `LDSR reg2, regID, selID` (selID = group number)
   - Current format: `LDSR reg2, regID` (selID=0 implied)
   - Need new instruction variants: `LDSR_SEL` and `STSR_SEL`

2. **Define G3M system registers** in `V850RegisterInfo.td`:
   - Add SystemRegG3M register class with (regID, groupID) encoding

3. **Add named builtins** for commonly-used registers (RBASE, EBASE, INTBP, etc.)

4. **Update existing LDSR/STSR intrinsics** to support optional group parameter:
   ```c
   void __builtin_v850_ldsr_group(unsigned int value, unsigned int regID, unsigned int group);
   unsigned int __builtin_v850_stsr_group(unsigned int regID, unsigned int group);
   ```

**Files:**
- `llvm/lib/Target/V850/V850RegisterInfo.td`
- `llvm/lib/Target/V850/V850InstrInfo.td`
- `clang/include/clang/Basic/BuiltinsV850.def`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp`

---

## Phase 4: Frame Optimization (Medium Priority)

### 4.1 PUSHSP/POPSP for Prologue/Epilogue

**Goal:** Use PUSHSP/POPSP for saving/restoring consecutive register ranges
in function prologues/epilogues. This is more efficient than individual
ST.W/LD.W for large register sets.

**Current State:** PREPARE/DISPOSE is used for callee-saved registers.
PUSHSP/POPSP supports contiguous register ranges.

**Difference from PREPARE/DISPOSE:**
- PREPARE uses a 12-bit list to select non-contiguous registers (r20-r31)
- PUSHSP takes a start-end range and saves ALL registers in the range
- PUSHSP is better for saving argument registers (r6-r9) or large ranges

**Implementation:**

1. **Analyze where PUSHSP/POPSP outperforms PREPARE/DISPOSE**:
   - PUSHSP rh-rt: Pushes r[rh] through r[rt] to stack
   - More efficient for contiguous ranges > 3 registers
   - Cannot replace PREPARE for non-contiguous register sets

2. **Add patterns in V850FrameLowering.cpp**:
   - For interrupt handlers that save all caller-saved registers
   - For functions with many callee-saved registers in a contiguous range

3. **Tests:**
   - `llvm/test/CodeGen/V850/g3m-pushsp-popsp.ll`

**Complexity:** Medium

---

## Phase 4b: System Register Refactoring [DONE]

### 4b.1 Unified 10-bit Encoding for LDSR/STSR

**Status:** Completed. See commit `[V850] Unify LDSR/STSR to 10-bit system register encoding`.

**What was implemented:**
- `Encoding = (selID << 5) | regID` — single 10-bit operand covers all banks
- `FormatIX_SysReg` class with `isCodeGenOnly = 1` (avoids STSR/SUBFS decoder conflict)
- `V850SystemOperands.td` extended: 10-bit `Encoding` field, G3M+ banked registers
  (Group 1: rbase, ebase, intbp, scbp_g1; Group 2: mea, mei, ispr, pmr, icsr, intcfg)
- AsmParser: named (`ldsr r1, ebase`), numeric (`ldsr r1, 3`), and
  numeric-with-selID (`ldsr r1, 3, 1`) syntax all handled
- InstPrinter: looks up 10-bit encoding — prints name if known, `regID` for selID=0
  unnamed, `regID, selID` for selID≠0 unnamed
- Disassembler: combines bits[4:0] (regID) and bits[20:16] (selID) into 10-bit imm
- Removed `LDSR_sel`/`STSR_sel` instructions and `int_v850_ldsr_sel`/`int_v850_stsr_sel`
- Clang builtins: `__builtin_v850_ldsr_group(val, regID, selID)` combines to 10-bit encoding

**Remaining limitation:** `FormatIX_SysReg` keeps `isCodeGenOnly = 1` because the TableGen
decoder emitter cannot disambiguate STSR (variable bits[20:16]) from SUBFS without it.
Disassembly is handled by custom code. Remaining G3M register groups (MPU, cache tags)
can be added to `V850SystemOperands.td` without further structural changes.

---

## Phase 4c: Double-Precision FPU CodeGen (Medium Priority)

### 4c.1 Current State

All double-precision FPU instructions are defined in the MC layer (assembler/disassembler)
but **none generate code from LLVM IR**. The hardware has full support but the backend
marks every `f64` operation as `Expand`, causing fallback to software library calls
(`__adddf3`, `__muldf3`, etc.).

**Root causes:**

1. **No DREG register class:** Double-precision uses even/odd GPR pairs (r0+r1, r2+r3,
   ..., r30+r31). There is no `DRegClass` / `GPRPair` register class in
   `V850RegisterInfo.td`.
2. **All f64 ops set to `Expand`** in `V850ISelLowering.cpp` (~line 259):
   `FADD/FSUB/FMUL/FDIV/FABS/FNEG/FSQRT/FP_EXTEND` for MVT::f64 → Expand.
3. **No ISel patterns:** All double-precision instructions have empty `[]` pattern
   lists in `V850InstrInfo.td`.
4. **Conversion instructions** (`CVTF.DS`, `CVTF.SD`, `CVTF.WD`, ...) all MC-only.
5. **Rounding instructions** (`TRNCF.D*`, `CEILF.D*`, `FLOORF.D*`, `ROUNDF.D*`) all
   MC-only. Only `TRNCF.SW` (single→int32) has an ISel pattern.

**What is complete:**

| Layer | Status |
|-------|--------|
| MC (assembler/disassembler) — all ~50 double instructions | ✅ Complete |
| f32 (single-precision) CodeGen — register class, ISel patterns, tests | ✅ Complete |
| Scheduling latencies (comments in V850SchedV850E2M.td) | ✅ Documented |
| f64 CodeGen — register class, ISel patterns, type lowering | ❌ Missing |

**Existing test files** (inline assembly only, not CodeGen):
- `llvm/test/CodeGen/V850/insn/fpu-arith-d.ll` — uses `asm sideeffect`, not real codegen
- `llvm/test/CodeGen/V850/insn/fpu-convert.ll`, `fpu-cmp.ll`, `fpu-round.ll` — same

### 4c.2 Implementation Plan

**Step 1 — Define GPR pair register class** (`V850RegisterInfo.td`):

```tablegen
// Sub-register indices for even/odd halves of a 64-bit pair
def sub_lo : SubRegIndex<32, 0>;
def sub_hi : SubRegIndex<32, 32>;

// Double-precision register pairs: even register holds LSW, odd holds MSW
// Pairs: (r0,r1), (r2,r3), (r4,r5), (r6,r7), (r8,r9), (r10,r11),
//        (r12,r13), (r14,r15), (r16,r17), (r18,r19), (r20,r21),
//        (r22,r23), (r24,r25), (r26,r27), (r28,r29), (r30,r31)
def DPR : RegisterClass<"V850", [f64], 64, (add ...)> {
  let SubRegClasses = [(FPR sub_lo), (FPR sub_hi)];
}
```

Register pairs are the same physical GPRs used for `f32` (`FPR`) and `i32` (`GPR`),
just paired. V850 hardware requires even-numbered register for the low word.

**Step 2 — Mark f64 operations as Legal** (`V850ISelLowering.cpp`):

```cpp
if (STI.hasV850FPU()) {
  addRegisterClass(MVT::f64, &V850::DPRRegClass);

  setOperationAction(ISD::FADD,    MVT::f64, Legal);
  setOperationAction(ISD::FSUB,    MVT::f64, Legal);
  setOperationAction(ISD::FMUL,    MVT::f64, Legal);
  setOperationAction(ISD::FDIV,    MVT::f64, Legal);
  setOperationAction(ISD::FABS,    MVT::f64, Legal);
  setOperationAction(ISD::FNEG,    MVT::f64, Legal);
  setOperationAction(ISD::FSQRT,   MVT::f64, Legal);
  setOperationAction(ISD::FMINNUM, MVT::f64, Legal);
  setOperationAction(ISD::FMAXNUM, MVT::f64, Legal);
  setOperationAction(ISD::FMA,     MVT::f64, Legal);
  setOperationAction(ISD::FP_ROUND,   MVT::f32, Legal); // double→float
  setOperationAction(ISD::FP_EXTEND,  MVT::f64, Legal); // float→double
  setOperationAction(ISD::FP_TO_SINT, MVT::i32, Legal); // double→int
  setOperationAction(ISD::SINT_TO_FP, MVT::f64, Legal); // int→double
}
```

**Step 3 — Add ISel patterns** (`V850InstrInfo.td`):

```tablegen
let Predicates = [HasV850FPU] in {
  def : Pat<(f64 (fadd DPR:$r2, DPR:$r1)), (ADDFD DPR:$r2, DPR:$r1)>;
  def : Pat<(f64 (fsub DPR:$r2, DPR:$r1)), (SUBFD DPR:$r2, DPR:$r1)>;
  def : Pat<(f64 (fmul DPR:$r2, DPR:$r1)), (MULFD DPR:$r2, DPR:$r1)>;
  def : Pat<(f64 (fdiv DPR:$r2, DPR:$r1)), (DIVFD DPR:$r2, DPR:$r1)>;
  def : Pat<(f64 (fabs DPR:$r2)),          (ABSFD DPR:$r2)>;
  def : Pat<(f64 (fneg DPR:$r2)),          (NEGFD DPR:$r2)>;
  def : Pat<(f64 (fsqrt DPR:$r2)),         (SQRTFD DPR:$r2)>;
  def : Pat<(f64 (fmaxnum DPR:$r2, DPR:$r1)), (MAXFD DPR:$r2, DPR:$r1)>;
  def : Pat<(f64 (fminnum DPR:$r2, DPR:$r1)), (MINFD DPR:$r2, DPR:$r1)>;
  // Conversions
  def : Pat<(f32 (fpround DPR:$r2)),        (CVTFDS DPR:$r2)>;  // double→float
  def : Pat<(f64 (fpextend FPR:$r2)),       (CVTFSD FPR:$r2)>;  // float→double
  def : Pat<(i32 (fp_to_sint DPR:$r2)),     (TRNCFDW DPR:$r2)>; // double→int32
  def : Pat<(f64 (sint_to_fp GPR:$r2)),     (CVTFWD GPR:$r2)>;  // int32→double
  // FMA
  def : Pat<(f64 (fma DPR:$r1, DPR:$r2, DPR:$r3)),  (MADDFD DPR:$r1, DPR:$r2, DPR:$r3)>;
  def : Pat<(f64 (fneg (fma DPR:$r1, DPR:$r2, DPR:$r3))), (NMADDFD DPR:$r1, DPR:$r2, DPR:$r3)>;
}
```

**Step 4 — Add scheduling rules** for double-precision instructions in
`V850SchedV850E2M.td` and `V850SchedRH850G3M.td`.

**Step 5 — Add f64 calling convention** (`V850CallingConv.td`):
- f64 return values: r10+r11 pair (low in r10, high in r11)
- f64 arguments: r6+r7, r8+r9 pairs

**Step 6 — Add tests:**
- `llvm/test/CodeGen/V850/fpu-double-arith.ll` — verify ADDF.D, SUBF.D, etc. generated
- `llvm/test/CodeGen/V850/fpu-double-convert.ll` — CVTF.DS, CVTF.SD, CVTF.WD
- `llvm/test/CodeGen/V850/fpu-double-compare.ll` — CMPF.D + TRFSR sequences
- `llvm/test/CodeGen/V850/fpu-double-calling-conv.ll` — register pair ABI

**Complexity:** Medium-High (register pairs are non-trivial in LLVM)

**Files:**
- `llvm/lib/Target/V850/V850RegisterInfo.td` — DPR register class, sub_lo/sub_hi indices
- `llvm/lib/Target/V850/V850ISelLowering.cpp` — f64 type actions, register class
- `llvm/lib/Target/V850/V850InstrInfo.td` — ISel patterns for all double instructions
- `llvm/lib/Target/V850/V850CallingConv.td` — f64 argument/return convention
- `llvm/lib/Target/V850/V850SchedV850E2M.td` — scheduling rules
- `llvm/lib/Target/V850/V850SchedRH850G3M.td` — G3M-specific scheduling rules

**Reference:** ARM backend (`llvm/lib/Target/ARM/`) uses `DPR` register pairs for
VFPv2 double-precision; MIPS uses `AFGR64` for similar even/odd FPR pairs.

---

## Phase 5: G3MH-Specific Features (Low Priority)

### 5.1 G3MH FPU Changes

**G3MH modifies several FPU aspects:**

1. **FPEC register deleted** - FPU exception cause merged into FPSR
2. **FPIPR register deleted** - Interrupt priority handled differently
3. **FPINT exception** - Replaces separate FPP and FPI exceptions
4. **RECIPF/RSQRTF precision** - Results may differ slightly from G3M

**Implementation:**
- Update `initFeatureMap()` to conditionally enable/disable FPEC/FPIPR
- Add `__rh850g3mh__` feature check for affected builtins
- Document precision differences

---

### 5.2 G3MH Cache Control Changes

**G3MH with instruction cache:**
- ICCTRL, ICTAGL, ICTAGH, ICCFG, ICERR registers
- Cache line management via CACHE instruction
- Cache clear/invalidate procedures

**Implementation:** Covered by system register additions in Phase 3.

---

## Phase 6: Post-Increment Addressing (Low Priority - G4MH Only)

### 6.1 Post-Increment Load/Store

**Goal:** Use post-increment addressing for loop optimization.

**NOTE:** Post-increment/decrement load/store instructions are **RH850G4MH only**.
They are NOT available on G3M or G3MH (verified against docs/rh850g3m.txt and
docs/rh850g3mh.txt — the addressing mode concept is described but no instructions
implement it). The instructions are first defined in docs/rh850g4mh.txt.

**G4MH adds post-increment/decrement forms (Format XI, 32-bit):**

| Instruction | Encoding bits[15:11] | sub-op bits[26:16] | Inc/Dec |
|-------------|---------------------|--------------------|---------|
| LD.B [reg1]+, reg3 | 00010 | 01101110000 | +1 |
| LD.B [reg1]-, reg3 | 00100 | 01101110000 | -1 |
| LD.BU [reg1]+, reg3 | 00011 | 01101110000 | +1 |
| LD.BU [reg1]-, reg3 | 00101 | 01101110000 | -1 |
| LD.H [reg1]+, reg3 | 00010 | 01101110100 | +2 |
| LD.H [reg1]-, reg3 | 00100 | 01101110100 | -2 |
| LD.HU [reg1]+, reg3 | 00011 | 01101110100 | +2 |
| LD.HU [reg1]-, reg3 | 00101 | 01101110100 | -2 |
| LD.W [reg1]+, reg3 | 00010 | 01101111000 | +4 |
| LD.W [reg1]-, reg3 | 00100 | 01101111000 | -4 |
| ST.B reg3, [reg1]+ | 00010 | 01101110010 | +1 |
| ST.B reg3, [reg1]- | 00100 | 01101110010 | -1 |
| ST.H reg3, [reg1]+ | 00010 | 01101110110 | +2 |
| ST.H reg3, [reg1]- | 00100 | 01101110110 | -2 |
| ST.W reg3, [reg1]+ | 00010 | 01101111010 | +4 |
| ST.W reg3, [reg1]- | 00100 | 01101111010 | -4 |

All use bits[10:5] = 111111, RRRRR = reg1, wwwww = reg3.
Constraint: reg1 != reg3 (same register causes undefined behavior).

**Implementation:**

1. **Add instruction definitions** in V850InstrInfo.td (Format XI)
2. **Add encoding/decoding** in MCCodeEmitter and Disassembler
3. **Add ISel patterns** for `ISD::POST_INC`/`ISD::POST_DEC`
4. **Set `setIndexedLoadAction()` / `setIndexedStoreAction()`** in ISelLowering
5. **Add assembler/disassembler tests**

**Requires:** `HasRH850G4MH` feature flag (NOT G3M)

**Complexity:** Medium-High (requires LSR integration)

**Files:**
- `llvm/lib/Target/V850/V850InstrInfo.td` - Instruction defs
- `llvm/lib/Target/V850/V850ISelLowering.cpp` - ISD configuration
- `llvm/lib/Target/V850/V850ISelDAGToDAG.cpp` - Pattern matching

---

## Phase 7: LOOP Instruction (Low Priority)

### 7.1 Hardware Loop

**Goal:** Use LOOP instruction for counted loops.

**LOOP reg1, disp16:**
- Decrements reg1, branches backward by disp16 if reg1 != 0
- Executes in 1 cycle when predicted (branch prediction)

**Implementation:**
- Requires a hardware loop optimization pass
- Match `br_cc (sub count, 1), ne, loop_head` → `LOOP count, disp`
- Consider implementing as a late MachineFunction pass

**Complexity:** High (hardware loop passes are complex)

---

## Phase 8: G4MH Features (Future)

### 8.1 Virtualization Instructions

**G4MH adds hypervisor support:**
- `HVTRAP vector5` - Hypervisor trap
- `LDM.GSR [reg1]` - Load multiple guest system registers
- `STM.GSR [reg1]` - Store multiple guest system registers
- `LDM.MP [reg1], eh-et` - Load MPU entries
- `STM.MP eh-et, [reg1]` - Store MPU entries

**Priority:** Future (requires G4MH subtarget)

### 8.2 FXU Vector Unit

**G4MH adds 128-bit SIMD (FXU):**
- 32 vector registers (wreg0-wreg31), 128-bit each
- 59 vector instructions (ADDF.S4, SUBF.S4, MULF.S4, etc.)
- Requires PSW.CU1 coprocessor enable

**Priority:** Future (significant effort, requires new register class)

---

## Implementation Order

### Sprint 1: Core CodeGen Improvements [DONE]
1. ~~[1.3] Atomic RMW via LDL.W/STC.W~~
2. ~~[2.1] CACHE builtin~~
3. ~~[2.2] PREF builtin~~

### Sprint 2: 64-bit and Bitfield Support [DONE]
4. ~~[1.1] LD.DW/ST.DW 64-bit load/store patterns~~
5. ~~[1.2] BINS bitfield insert patterns + builtin~~

### Sprint 3: System Registers [DONE]
6. ~~[3.1] LDSR/STSR with group specification~~
7. ~~[3.1] Named builtins for key G3M system registers~~

### Sprint 4: Frame Optimization [DONE]
8. ~~[4.1] PUSHSP/POPSP frame optimization~~

### Sprint 5: System Register Refactoring [DONE]
9. ~~[4b.1] Replace SysReg pseudo register class with immediate operands~~
10. ~~Unify LDSR/LDSR_sel into single instruction with 10-bit (selID<<5)|regID encoding~~

### Sprint 6: Double-Precision FPU CodeGen
11. [4c.1] Define DPR register pair class (sub_lo, sub_hi indices, even/odd GPR pairs)
12. [4c.1] Mark f64 operations Legal in ISelLowering, add DPR register class
13. [4c.1] Add ISel patterns for all double-precision instructions
14. [4c.1] Add f64 calling convention (r10+r11 return, r6+r7/r8+r9 args)
15. [4c.1] Add scheduling rules for ADDF.D, MULF.D, DIVF.D, SQRTF.D etc.

### Sprint 7: LOOP and G3MH
16. [7.1] LOOP instruction pass (if feasible)
17. [5.1] G3MH FPU differences (FPEC deletion, FPINT exception)

### Sprint 8: Post-Increment (G4MH Only)
18. [6.1] Post-increment load/store instructions and ISel patterns (requires G4MH subtarget)

---

## Verification

For each sprint:
1. `ninja -C build-v850 V850CommonTableGen` - TableGen must succeed
2. `ninja -C build-v850` - Full build must succeed
3. `build-v850/bin/llvm-lit -j8 llvm/test/MC/V850/ llvm/test/MC/Disassembler/V850/ llvm/test/CodeGen/V850/` - All tests pass
4. New tests added for each feature

---

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2026-02-11 | 1.0 | Initial plan with comprehensive feature analysis |
| 2026-02-11 | 1.1 | Sprints 1-4 complete; Added Phase 4b: SysReg refactoring (replace pseudo regs with immediates); Updated sprint order; Fixed LoadStoreOptimizer volatile crash |
| 2026-02-21 | 1.2 | Sprint 5 complete: unified 10-bit encoding `(selID<<5)\|regID` for LDSR/STSR, named banked register syntax (ebase, intbp, mea, etc.), removed LDSR_sel/STSR_sel; Added Phase 4c: Double-Precision FPU CodeGen (all f64 ops currently fall back to libcalls — no DPR register class, no ISel patterns) |
