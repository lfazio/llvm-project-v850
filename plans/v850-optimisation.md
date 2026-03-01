# V850 Backend Optimization Plan

This document catalogs all optimizations for the V850 LLVM backend, indicating their implementation status and priority.

## Legend

- **[IMPLEMENTED]** - Optimization is fully implemented and tested
- **[PARTIAL]** - Optimization is partially implemented
- **[TODO]** - Optimization is planned but not yet implemented
- **[FUTURE]** - Optimization is desirable but lower priority

---

## 1. Machine Passes

### 1.1 Load/Store Optimizer [IMPLEMENTED]

**File:** `llvm/lib/Target/V850/V850LoadStoreOptimizer.cpp`

**Description:** Promotes 32-bit LD.W/ST.W instructions to 16-bit SLD.W/SST.W when:
- Base register is EP (r30)
- Displacement fits in the shorter format

**Benefits:**
- Reduces code size by 2 bytes per instruction
- Faster instruction fetch

**Status:** Fully implemented with pass registration in V850TargetMachine.cpp

---

### 1.2 Branch Relaxation [IMPLEMENTED]

**File:** Uses LLVM's `BranchRelaxationPassID`

**Description:** Expands conditional branches that are out of range by:
1. Inverting the condition
2. Inserting an unconditional branch to the original target

**Implementation Details:**
- `V850InstrInfo::analyzeBranch()` - Branch analysis
- `V850InstrInfo::insertBranch()` - Branch insertion
- `V850InstrInfo::removeBranch()` - Branch removal
- `V850InstrInfo::getBranchDestBlock()` - Get branch target

**Status:** Fully implemented, runs in addPreEmitPass()

---

### 1.3 Machine Outliner [IMPLEMENTED]

**File:** `llvm/lib/Target/V850/V850InstrInfo.cpp` (lines 395-544)

**Description:** Extracts common instruction sequences into shared functions to reduce code size.

**Implementation Details:**
- `getOutliningCandidateInfo()` - Identifies outlining candidates
- `buildOutlinedFrame()` - Creates the outlined function frame
- `insertOutlinedCall()` - Replaces sequences with calls
- Cost model for JARL (4 bytes) vs JR (2 bytes)

**Outlining Types:**
- `MachineOutlinerDefault` - Standard call with JARL
- `MachineOutlinerTailCall` - Tail call optimization with JR

**Status:** Fully implemented with complete cost model

---

### 1.4 Atomic Expand Pass [IMPLEMENTED]

**File:** `llvm/lib/Target/V850/V850TargetMachine.cpp`

**Description:** Expands atomic RMW operations to compare-and-swap loops.

**V850E2M Support:**
- CAXI instruction for 32-bit compare-and-swap
- Expansion for 8-bit and 16-bit atomics
- Custom lowering of ATOMIC_FENCE to SYNCP instruction
- Custom lowering of ATOMIC_LOAD/ATOMIC_STORE (i32) to regular load/store
- `shouldInsertFencesForAtomic()` returns true for loads/stores, causing AtomicExpandPass
  to insert SYNCP fences for ordered atomics and reduce ordering to monotonic
- `MaxAtomicInlineWidth = 32` in Clang TargetInfo enables lock-free atomics

**RH850G3M Support:**
- LDL.W (load linked) instruction for exclusive access
- STC.W (store conditional) instruction for atomic store
- CLL (clear link) instruction to clear link state
- Intrinsics: `__builtin_v850_ldl_w()`, `__builtin_v850_stc_w()`, `__builtin_v850_cll()`
- Note: stdatomic currently uses CAXI path (V850E2M), NOT LDL.W/STC.W

**Fence Placement (single-core in-order):**
| Operation | Fences |
|-----------|--------|
| Relaxed load | (none) |
| Acquire load | trailing SYNCP |
| Seq_cst load | trailing SYNCP |
| Relaxed store | (none) |
| Release store | leading SYNCP |
| Seq_cst store | leading + trailing SYNCP |

**Files:**
- `llvm/lib/Target/V850/V850ISelLowering.cpp` - Custom lowering
- `llvm/lib/Target/V850/V850ISelLowering.h` - Declarations
- `clang/lib/Basic/Targets/V850.cpp` - MaxAtomicInlineWidth
- `llvm/test/CodeGen/V850/atomic-load-store.ll` - Tests

**Status:** Fully implemented via `createAtomicExpandLegacyPass()` + custom lowering

---

### 1.5 Peephole Optimizer [IMPLEMENTED]

**File:** `llvm/lib/Target/V850/V850PeepholeOptimizer.cpp`

**Description:** Local instruction combining for common patterns.

**Implemented Patterns:**
1. `MOV r0, rX` + `ADD imm, rX` → `MOV imm, rX` - Fold zero move and add into immediate move
2. Redundant ANDI removal after zero-extending loads (LDBU produces 0xFF, LDHU produces 0xFFFF)
3. Copy propagation for consecutive MOV instructions

**Implementation Details:**
- MachineFunctionPass running in addPreEmitPass() before load/store optimizer
- Uses MachineRegisterInfo for def-use chain analysis
- Statistics tracking via LLVM_DEBUG for optimization counts

**Status:** Fully implemented with pass registration in V850TargetMachine.cpp

---

### 1.6 If Conversion [IMPLEMENTED]

**Description:** Convert simple if-then-else to conditional moves using CMOV.

**Requirements:**
- V850ES or later (CMOV introduced in V850ES)
- Simple control flow with no side effects

**Implementation Details:**
- `V850InstrInfo::canInsertSelect()` - Determines if CMOV can be used
- `V850InstrInfo::insertSelect()` - Generates CMOV instruction
- EarlyIfConversion pass enabled in `V850TargetMachine::addPreRegAlloc()`
- Maps branch condition codes to CMOV condition codes (0-15)

**Status:** Fully implemented with EarlyIfConversion pass integration

---

### 1.7 Post-RA Scheduler [IMPLEMENTED]

**Files:**
- `llvm/lib/Target/V850/V850Schedule.td` - Base V850 model
- `llvm/lib/Target/V850/V850SchedV850E1.td` - V850E1 model
- `llvm/lib/Target/V850/V850SchedV850E2M.td` - V850E2M model
- `llvm/lib/Target/V850/V850Subtarget.cpp` - Anti-dependency breaking

**Description:** Instruction scheduling after register allocation to reduce stalls and improve dual-issue utilization.

**Implementation Details:**
- `PostRAScheduler = true` enabled in all scheduling models (V850, V850E1, V850E2M)
- `getAntiDepBreakMode()` returns `ANTIDEP_ALL` for aggressive anti-dependency breaking
- `getCriticalPathRCs()` prioritizes GPR register class for critical path analysis
- V850E2M benefits most from dual-issue (Lpipe + Rpipe) optimization

**Benefits:**
- Better utilization of V850E2M dual-issue capability
- Reduced pipeline stalls from load-use hazards
- Anti-dependency breaking allows more scheduling freedom

**Status:** Fully implemented with anti-dependency breaking support

---

## 2. Instruction Selection (DAG Combine)

### 2.1 Bit Operation Combining [IMPLEMENTED]

**File:** `llvm/lib/Target/V850/V850ISelLowering.cpp`

**Function:** `performSTORECombine()`

**Description:** Combines load-modify-store sequences into atomic bit operations:
- `SET1` - Set bit
- `CLR1` - Clear bit
- `NOT1` - Toggle bit
- `TST1` - Test bit

**Pattern:**
```
load → or/and/xor → store  →  SET1/CLR1/NOT1 [disp], reg
```

**Status:** Fully implemented

---

### 2.2 MAC/MACU Pattern Combining [IMPLEMENTED]

**File:** `llvm/lib/Target/V850/V850ISelLowering.cpp`

**Function:** `performADDCombine()`

**Description:** Combines multiply-add sequences into MAC/MACU instructions.

**Pattern:**
```
mul → add  →  MAC reg1, reg2, reg3, reg4 (adds to reg3:reg4)
```

**Requirements:** V850E1 or later

**Status:** Fully implemented

---

### 2.3 ADF/SBF 64-bit Arithmetic [IMPLEMENTED]

**File:** `llvm/lib/Target/V850/V850ISelLowering.cpp`, `llvm/lib/Target/V850/V850InstrInfo.td`

**Functions:** `performADDECombine()`, ISel patterns for addc/adde/subc/sube

**Description:** Uses ADF/SBF instructions for efficient 64-bit add/subtract with carry propagation.

**Instructions:**
- ADF cond, reg1, reg2, reg3: reg3 = reg2 + reg1 + (cond ? 1 : 0)
- SBF cond, reg1, reg2, reg3: reg3 = reg2 - reg1 - (cond ? 1 : 0)

**Pattern:**
```
i64 add:  ADD (low) + ADF C (high with carry)
i64 sub:  SUB (low) + SBF C (high with borrow)
```

**Implementation Details:**
- ADDC/ADDE/SUBC/SUBE set to Legal on V850E2+
- ISel patterns: addc→ADD, adde→ADF, subc→SUB, sube→SBF
- ADF/SBF define PSW for chained operations (e.g., i128 add)
- performADDECombine recognizes MAC patterns with ADDC/ADDE

**Code Generation Improvement:**
| Operation | V850E2M (ADF/SBF) | V850E1 (setf) |
|-----------|-------------------|---------------|
| i64 add   | add + adf c (4)   | add + setf c + add + add (7) |
| i64 sub   | sub + sbf c (4)   | setf c + sub + sub + sub (7) |

**Requirements:** V850E2 or later

**Status:** Fully implemented

---

### 2.5 DIVQ/DIVQU Quick Division [IMPLEMENTED]

**Description:** Use DIVQ/DIVQU for divisions when quotient is known to fit.

**Pattern:**
```
Signed division where |dividend| >> |divisor| → DIVQ
Unsigned division where dividend >> divisor → DIVQU
```

**Requirements:** V850E2M or later

**Implementation Details:**
- DIVQ/DIVQU defined in `V850InstrInfo.td` (lines 1304-1338)
- Variable-step execution: N+4 to N+5 cycles (vs 36 for DIV)
- `AddedComplexity = 10` ensures selection over DIV/DIVU on V850E2M
- Pattern-matched via V850ISD::SDIVREM/UDIVREM nodes

**Status:** Fully implemented with instruction selection patterns

---

### 2.6 SWITCH Instruction for Jump Tables [IMPLEMENTED]

**File:** `llvm/lib/Target/V850/V850ISelLowering.cpp`

**Description:** Uses V850's SWITCH instruction for efficient jump table dispatch.

**Pattern:**
```
Index bounds check → table lookup → indirect jump  →  SWITCH reg
```

**Status:** Fully implemented with jump table lowering

---

### 2.7 SXB/SXH/ZXB/ZXH Extension [IMPLEMENTED]

**Description:** Sign/zero extension using dedicated instructions.

**Status:** Implemented in instruction selection patterns

---

### 2.8 BSH/BSW Byte Swap [IMPLEMENTED]

**Description:** Byte swap operations using BSH (halfword) and BSW (word).

**Status:** Implemented for bswap intrinsics

---

### 2.9 SASF Shift-and-Add with Sign Flag [IMPLEMENTED]

**Description:** Use SASF for shift-add sequences that depend on condition codes.

**Pattern:**
```c
// Before:
int bit = (a > b) ? 1 : 0;
result = (x << 1) | bit;

// After:
cmp a, b
sasf gt, x    // x = (x << 1) | (condition ? 1 : 0)
```

**Implementation:**
- DAG combine in `performORCombine()` matches `(or (shl x, 1), (setcc ...))`
- Converts to `V850ISD::CMP` + `V850ISD::SASF` nodes
- Custom instruction selection emits `CMP` + `SASF` sequence
- Supports all standard comparison conditions (eq, ne, lt, le, gt, ge, ult, ule, ugt, uge)

**Files Modified:**
- `V850ISelLowering.h`: Added `V850ISD::SASF` enum
- `V850ISelLowering.cpp`: Added `performORCombine()` and `setTargetDAGCombine(ISD::OR)`
- `V850ISelDAGToDAG.cpp`: Added custom selection for `V850ISD::SASF`
- `V850InstrInfo.td`: Added `V850sasf` SDNode definition

**Requirements:** V850ES (V850E1) or later

**Status:** Implemented with tests in `llvm/test/CodeGen/V850/sasf.ll`

---

### 2.10 HSH/HSW Half-word Swap [IMPLEMENTED]

**Description:** Use HSH/HSW for specific rotation/swap patterns.

**Requirements:** V850E1+ for HSW, V850E2+ for HSH

**Implementation Details:**
- HSW (halfword swap word): `V850InstrInfo.td` lines 1403-1415
- Pattern: `(rotr GPR:$reg2, (i32 16))` → HSW
- Also matches explicit OR/SHL/SRL patterns for 16-bit rotation
- HSH (halfword swap halfword): `V850InstrInfo.td` lines 1665-1671
- Intrinsic: `__builtin_v850_hsh()` implemented

**Status:** Fully implemented with instruction selection patterns

---

### 2.11 SCH Search Operations [IMPLEMENTED]

**Description:** Use SCH0L/SCH0R/SCH1L/SCH1R for leading/trailing zero/one counting.

**Pattern:**
```
ctlz(x) → SCH1L    (count leading zeros)
cttz(x) → SCH1R    (count trailing zeros)
ctlz(not x) → SCH0L (count leading ones)
cttz(not x) → SCH0R (count trailing ones)
```

**Requirements:** V850E2+ or later

**Implementation Details:**
- Instructions defined in `V850InstrInfo.td` lines 1551-1597
- Direct pattern matching from ISD::CTLZ/CTTZ
- ISelLowering marks CTLZ/CTTZ as Legal for V850E2+
- Intrinsics: `__builtin_v850_sch1l/r()`, `__builtin_v850_sch0l/r()`

**Status:** Fully implemented with instruction selection patterns

---

### 2.12 Saturating Arithmetic [IMPLEMENTED]

**Description:** Use SATADD/SATSUB/SATSUBI for saturating arithmetic.

**Pattern:**
```
ISD::SADDSAT → SATADD (2-operand) or SATADD_3 (3-operand)
ISD::SSUBSAT → SATSUB (2-operand) or SATSUB_3 (3-operand)
```

**Implementation Details:**
- SATADD/SATSUB: `V850InstrInfo.td` lines 411-426 (base V850)
- SATADD_3/SATSUB_3: `V850InstrInfo.td` lines 1634-1654 (V850E2+)
- 3-operand versions preferred via `AddedComplexity = 1`
- Direct pattern matching from ISD::SADDSAT/SSUBSAT

**Status:** Fully implemented with instruction selection patterns

---

## 3. Frame Optimization

### 3.1 PREPARE/DISPOSE [IMPLEMENTED]

**File:** `llvm/lib/Target/V850/V850FrameLowering.cpp`

**Description:** Uses PREPARE for function prologue and DISPOSE for epilogue.

**Benefits:**
- Single instruction saves/restores multiple registers
- Automatically adjusts SP
- Reduces code size significantly

**Requirements:** V850ES or later

**Status:** Fully implemented

---

### 3.2 Tail Call Optimization [IMPLEMENTED]

**File:** `llvm/lib/Target/V850/V850ISelLowering.cpp`

**Function:** `isEligibleForTailCallOptimization()`

**Description:** Replaces call+return with direct jump when:
- Callee's arguments fit in caller's frame
- No byval arguments
- Return types match

**Status:** Fully implemented with eligibility checking

---

### 3.3 Callee-Saved Register Shrink Wrapping [IMPLEMENTED]

**Description:** Move save/restore code closer to where registers are actually used.

**Files:**
- `llvm/lib/Target/V850/V850FrameLowering.h` - `enableShrinkWrapping()` declaration
- `llvm/lib/Target/V850/V850FrameLowering.cpp` - Implementation
- `llvm/lib/Target/V850/V850InstrInfo.td` - RET instruction fix (removed `Uses = [LP]`)
- `llvm/test/CodeGen/V850/shrink-wrap.ll` - Test cases

**Benefits:**
- Faster early returns (no PREPARE/DISPOSE overhead)
- Reduced register pressure in common paths

**Implementation Details:**
- `enableShrinkWrapping()` returns `true` when optimizing
- RET instruction no longer declares LP in Uses (following RISC-V/ARM pattern)
- Shrink wrapping moves PREPARE/DISPOSE to blocks that actually need callee-saved registers
- Early exit paths skip prologue/epilogue entirely

**Status:** Fully implemented with comprehensive tests

---

### 3.4 Stack Slot Coloring [PARTIAL]

**Description:** LLVM's stack slot coloring pass is enabled by default.

**V850 Specific:**
- Could benefit from EP-relative addressing optimization

**Priority:** Low

---

### 3.5 CFI Directive Emission [IMPLEMENTED]

**File:** `llvm/lib/Target/V850/V850FrameLowering.cpp`

**Description:** Emits Call Frame Information (CFI) directives for DWARF-based
stack unwinding support. CFI directives enable debuggers and exception handlers
to properly unwind the stack during debugging or exception handling.

**Implementation Details:**
- Uses `CFIInstBuilder` utility class from `llvm/CodeGen/CFIInstBuilder.h`
- Emits `.cfi_def_cfa_offset` after stack pointer adjustments
- Emits `.cfi_offset` for each callee-saved register after PREPARE
- Handles both PREPARE-based and fallback store-based callee-saved register saving
- Tracks callee-saved stack size in `V850MachineFunctionInfo`

**CFI Directives Emitted:**
1. After PREPARE: `.cfi_def_cfa_offset <callee_saved_size>`
2. After PREPARE: `.cfi_offset <reg>, <offset>` for each saved register
3. After stack allocation: `.cfi_def_cfa_offset <total_size>`
4. With frame pointer: `.cfi_def_cfa r29, <offset>`

**Benefits:**
- Enables GDB/LLDB stack unwinding
- Required for C++ exception handling
- Enables accurate crash reports and profiling

**Test:** `llvm/test/CodeGen/V850/cfi-directives.ll`

**Status:** Fully implemented

---

## 4. Scheduling Models

### 4.1 V850 Base Scheduling [IMPLEMENTED]

**File:** `llvm/lib/Target/V850/V850Schedule.td`

**Description:** Single-issue, 5-stage pipeline model:
- IF → ID → EX → MEM → WB
- 36-cycle DIVH
- 2-cycle loads
- 3-cycle branch misprediction penalty

**Status:** Fully implemented

---

### 4.2 V850E1 Scheduling [IMPLEMENTED]

**File:** `llvm/lib/Target/V850/V850SchedV850E1.td`

**Description:** Enhanced model for V850E1:
- MAC/MACU support (3 cycles)
- Improved multiply timing

**Status:** Fully implemented

---

### 4.3 V850E2M Dual-Issue Scheduling [IMPLEMENTED]

**File:** `llvm/lib/Target/V850/V850SchedV850E2M.td`

**Description:** Dual-issue model with Lpipe/Rpipe:
- FPU instructions (single/double precision)
- Pairing rules for dual-issue
- Longer latencies for division/sqrt

**Status:** Fully implemented

---

### 4.4 RH850G3M Scheduling [IMPLEMENTED]

**File:** `llvm/lib/Target/V850/V850SchedRH850G3M.td`

**Description:** Scheduling model for G3M/G3MH variants with improved timing over V850E2M.

**Key Differences from V850E2M:**
- Division: 19 cycles (was 36)
- DIVQ/DIVQU: N+3 cycles (was N+5)
- DIVF.S: 14 cycles (was 35), DIVF.D: 30 cycles (was 64)
- SQRTF.S: 14 cycles (was 30), SQRTF.D: 30 cycles (was 60)
- RECIPF.S: 10, RECIPF.D: 26, RSQRTF.S: 14, RSQRTF.D: 36
- LDSR: 3 cycles (was 4)
- Branch prediction support (1 cycle predicted, 4 mispredict)
- G3M-specific instructions: LD.DW, ST.DW, LDL.W, STC.W, CLL, ROTL, BINS,
  PUSHSP, POPSP, LOOP, CACHE, PREF, SYNCI, SNOOZE, Bcond disp17

**Implementation Details:**
- `RH850G3MModel`: Dual-issue, in-order, same pipeline structure as V850E2M
- InstRW overrides for all G3M-specific instructions
- InstRW overrides for RECIPF/RSQRTF with separate latencies
- New SchedWrite types: WriteLDDW, WriteSTDW, WriteLDLW, WriteSTCW, WriteCLL,
  WriteROTL, WriteBINS, WritePUSHSP, WritePOPSP, WriteLOOP, WriteCACHE,
  WriteG3MPREF, WriteSYNCI, WriteSNOOZE

**Status:** Fully implemented

---

### 4.5 RH850G4MH Scheduling [TODO]

**Description:** Scheduling model for G4MH with:
- Improved FPU timing
- Virtualization overhead
- Extended register file

**Priority:** Low

---

## 5. Code Size Optimizations

### 5.1 16-bit Instruction Preference [IMPLEMENTED]

**Description:** Prefer 16-bit instruction forms when possible:
- Short load/store (SLD/SST)
- Short branch
- Short immediate operations

**Status:** Implemented in instruction selection

---

### 5.2 Literal Pool / Constant Pool Support [IMPLEMENTED]

**Description:** Support for floating-point and large constants via constant pools.

**Files:**
- `llvm/lib/Target/V850/V850ISelLowering.cpp` - LowerConstantPool implementation
- `llvm/lib/Target/V850/V850ISelLowering.h` - Declaration
- `llvm/lib/Target/V850/V850InstrInfo.td` - FPU load/store instructions and patterns
- `llvm/test/CodeGen/V850/constant-pool.ll` - Tests

**Implementation Details:**
- Custom lowering for ISD::ConstantPool in V850ISelLowering
- V850ISD::WRAPPER node wraps constant pool addresses
- LDW_F/STW_F codegen-only instructions for f32 loads/stores (same encoding as LDW/STW)
- Patterns for f32 load/store with base register and offset
- Constants placed in .sdata section with MOVHI+MOVEA address materialization

**Code Generation:**
```
.section .sdata
.LCPI0_0:
    .word 0x40490fdb          ; float constant

return_float_const:
    movhi .LCPI0_0, r0, r10   ; Address high bits
    movea .LCPI0_0, r10, r10  ; Address low bits
    ld.w 0[r10], r10          ; Load constant
    jmp [r31]
```

**Status:** Implemented - floating-point constants now work correctly

---

### 5.3 Function Alignment Optimization [IMPLEMENTED]

**Description:** Optimize function alignment based on optimization level.

**Files:**
- `llvm/lib/Target/V850/V850ISelLowering.cpp` - setPrefFunctionAlignment
- `llvm/test/CodeGen/V850/function-alignment.ll` - Tests

**Implementation Details:**
- Minimum alignment: 2 bytes (for 16-bit instructions)
- Preferred alignment: 4 bytes (for better 32-bit instruction fetch)
- When `-Os` (optsize) is used, functions use minimum 2-byte alignment
- Default functions use preferred 4-byte alignment for performance

**Code Generation:**
```asm
; Normal function (-O2)
    .globl normal_function
    .p2align 2              ; 4-byte alignment

; Size-optimized function (-Os)
    .globl optsize_function
    .p2align 1              ; 2-byte alignment
```

**Notes:**
- The `minsize` attribute currently does not reduce alignment due to a known
  LLVM limitation (MachineFunction.cpp checks `OptimizeForSize` directly
  instead of using `hasOptSize()` which handles both attributes)

**Status:** Implemented

---

### 5.4 Constant Materialization [IMPLEMENTED]

**Description:** Efficient loading of constants:
- `MOV imm5, reg` for small signed constants (-16 to 15)
- `MOVEA imm16, r0, reg` for 16-bit signed constants (-32768 to 32767)
- `MOVHI imm16, r0, reg` for constants with zero low 16 bits (e.g., 0x10000, 0xFFFF0000)
- `MOVHI + MOVEA` for full 32-bit constants with non-zero low bits

**Files:**
- `llvm/lib/Target/V850/V850InstrInfo.td` - Pattern predicates and transforms
- `llvm/test/CodeGen/V850/const-materialization.ll` - Comprehensive tests

**Implementation Details:**
- `simm16_pred`: Matches constants fitting in 16-bit signed range
- `imm_hi16_only`: Matches constants with zero low 16 bits (MOVHI optimization)
- `imm32_pred`: Matches constants requiring both MOVHI+MOVEA
- `HI16`/`LO16`: Transforms to split 32-bit constants with sign-extension handling
- `HI16_ONLY`: Transform for MOVHI-only constants (no sign-extension adjustment needed)

**Optimization Impact:**
- Constants like 0x10000, 0x20000, 0xFFFF0000 now use single MOVHI (was MOVHI+MOVEA)
- Saves one instruction for any constant where low 16 bits are zero

**Status:** Fully implemented with comprehensive tests

---

## 6. Loop Optimizations

### 6.1 Hardware Loop Support [TODO]

**Description:** V850 has no hardware loop counter, but can benefit from:
- Loop unrolling hints
- Post-increment addressing in loops

**Priority:** Low

---

### 6.2 Post-Increment Addressing [HARDWARE LIMITATION]

**Description:** Use post-increment load/store where available.

**Hardware Support:**
- **V850/V850E1/V850E2/V850E2M:** NOT AVAILABLE
- **RH850G3M/G3MH/G4MH:** Available (`LD.W [reg]+, reg3`, `ST.W reg3, [reg]+`)

**Current Implementation:**
The V850 backend generates optimal code for array/pointer iteration patterns:
```asm
ld.w  0[r7], r10     ; load from ptr
add   4, r7          ; increment ptr
```

With hardware post-increment (RH850 only), this could be:
```asm
ld.w  [r7]+, r10     ; load and increment in one instruction
```

**Analysis:**
- Current code generation is OPTIMAL for V850E2M given available instructions
- Loop strength reduction is working (uses pointer increment, not index multiply)
- Hardware post-increment requires RH850 subtarget support

**Future Work:**
- Add RH850G3M/G4MH processor definitions
- Implement Format XI post-increment load/store instructions
- Add DAG patterns for ISD::POST_INC/POST_DEC

**Status:** No optimization possible for V850E2M (hardware limitation)
**Priority:** Low (requires RH850 backend work)

---

### 6.3 Loop Strength Reduction [TODO]

**Description:** Convert expensive operations in loops to cheaper incremental forms.

**Priority:** Low (LLVM middle-end handles most cases)

---

## 7. FPU Optimizations (V850E2M)

### 7.1 FMA Patterns [IMPLEMENTED]

**Description:** Use MAFF/MSFF/NMFF for fused multiply-add operations.

**Status:** Instruction patterns implemented

---

### 7.2 SIMD-like Operations [IMPLEMENTED]

**Description:** Optimize byte manipulation, saturating arithmetic, and FPU operations.

**Files:**
- `llvm/lib/Target/V850/V850InstrInfo.td` - BSH/FMA patterns
- `llvm/test/CodeGen/V850/simd-like-ops.ll` - Tests
- `llvm/test/CodeGen/V850/byte-swap.ll` - Updated tests

**Optimizations Implemented:**

1. **Byte Swap Operations:**
   - `bswap i32` → `BSW` (full word byte swap)
   - `bswap i16` → `BSH` (optimized from BSW+SHR to single instruction)

2. **Rotate Operations:**
   - `rotl/rotr by 16` → `HSW` (halfword swap)

3. **Saturating Arithmetic:**
   - `sadd.sat` → `SATADD`
   - `ssub.sat` → `SATSUB`

4. **FPU Min/Max:**
   - `fminnum` → `MINF.S`
   - `fmaxnum` → `MAXF.S`

5. **FMA Operations (Fixed):**
   - `fma(a, b, c)` → `MADDF.S` (was crashing, now works)
   - `fneg(fma(a, b, c))` → `NMADDF.S` (negate-multiply-add)

**Code Generation Examples:**
```asm
; bswap16 - optimized to single instruction
bsh r6, r10              ; was: bsw + shr 16

; FMA operation
maddf.s r6, r7, r8, r10  ; r10 = (r7 * r6) + r8
```

**Status:** Implemented

---

### 7.3 FP Constant Folding [IMPLEMENTED]

**Description:** Fold floating-point constants at compile time.

**Implementation Details:**
- LLVM middle-end (InstCombine) handles pure constant operations
- DAGCombiner handles identity operations with proper IEEE 754 compliance

**Optimizations Performed:**

| Pattern | Result | Conditions |
|---------|--------|------------|
| `fadd c1, c2` | Computed constant | Always |
| `fmul c1, c2` | Computed constant | Always |
| `fdiv c1, c2` | Computed constant | Always |
| `fma(c1, c2, c3)` | Computed constant | Always |
| `fadd x, -0.0` | x (identity) | Always (IEEE 754 compliant) |
| `fadd x, 0.0` | x (identity) | Only with `nsz` or `-fno-signed-zeros` |
| `fsub x, 0.0` | x (identity) | Only with `nsz` or `-fno-signed-zeros` |
| `fmul x, 1.0` | x (identity) | Always |
| `fmul x, 2.0` | `addf.s x, x` | Always |

**IEEE 754 Compliance Notes:**
- `x + 0.0` is NOT always identity: `-0.0 + 0.0 = +0.0` (sign changes)
- Optimization only applied when fast-math flags allow

**Example Output:**
```asm
; fadd x, 0.0 with nsz flag - optimized to identity
test_add_0_nsz:
    mov r6, r10              ; just copy input to output
    jmp [r31]

; fadd x, 0.0 without flags - keeps operation (IEEE 754 correct)
test_add_0_strict:
    movhi .LCPI0_0, r0, r10
    movea .LCPI0_0, r10, r10
    ld.w 0[r10], r10
    addf.s r10, r6, r10      ; must do the add
    jmp [r31]
```

**Status:** Implemented via LLVM infrastructure (no V850-specific code needed)

---

## 8. Memory Optimizations

### 8.1 EP-Relative Addressing [IMPLEMENTED]

**Description:** Use Element Pointer (EP/r30) for efficient memory access.

**Benefits:**
- 16-bit load/store forms
- Reduced code size

**Status:** Load/Store Optimizer promotes to EP-relative forms

---

### 8.2 GP-Relative Addressing [IMPLEMENTED]

**Description:** Use Global Pointer (GP/r4) for small data access.

**Implementation Details:**
- `V850TargetObjectFile` classifies globals into .sdata/.sbss sections
- `V850ISD::GPRel` node for GP-relative address computation
- `LowerGlobalAddress()` checks `IsGlobalInSmallSection()` and generates GP-relative addressing
- GP-relative load/store patterns in `V850InstrInfo.td`
- `fixup_v850_sda_16` maps to `R_V850_SDA_16_16_OFFSET` relocation

**Command Line Options:**
- `-v850-ssection-threshold=N` - Set small data threshold (default 8 bytes)
- `-v850-local-sdata` - Enable GP-rel for local data (default on)
- `-v850-extern-sdata` - Enable GP-rel for external data (default on)

**Benefits:**
- Single instruction load/store vs movhi+movea+load/store sequence
- Reduced code size for small global variable access

**Status:** Fully implemented with relocation support

---

### 8.3 Memory Barrier Optimization [PARTIAL]

**Description:** Optimize memory barriers for V850E2M.

**Instructions:**
- SYNCI/SYNCE/SYNCM/SYNCP

**Status:** Intrinsics implemented, optimization for barrier strength TODO

**Priority:** Low

---

## 9. ABI Optimizations

### 9.1 Register Parameter Passing [IMPLEMENTED]

**Description:** Pass arguments in registers r6-r9 per V850 EABI.

**Status:** Implemented in calling convention

---

### 9.2 Small Return Optimization [IMPLEMENTED]

**Description:** Return small structs in registers when possible.

**Status:** Basic support implemented

---

### 9.3 Varargs Support [IMPLEMENTED]

**Description:** Variable argument (varargs) function support.

**Implementation Details:**
- `V850MachineFunctionInfo` class tracks varargs frame index
- Custom `ISD::VASTART` lowering stores varargs area pointer to va_list
- `LowerFormalArguments` creates fixed stack object for varargs area
- Fixed `V850ISD::CALL` ISel to properly pass register operands

**Files:**
- `llvm/lib/Target/V850/V850MachineFunctionInfo.h` - New MFI class
- `llvm/lib/Target/V850/V850ISelLowering.cpp` - VASTART lowering
- `llvm/lib/Target/V850/V850ISelDAGToDAG.cpp` - Fixed CALL selection
- `llvm/lib/Target/V850/V850TargetMachine.cpp` - MFI registration
- `llvm/test/CodeGen/V850/varargs.ll` - Tests

**Calling Convention:**
- First 4 arguments: r6, r7, r8, r9
- Additional arguments: on stack
- va_list: pointer to first vararg on stack

**Example:**
```c
int sum(int count, ...) {
    va_list ap;
    va_start(ap, count);
    // ap now points to stack after 'count'
    ...
}
```

**Generated Assembly:**
```asm
varargs_receiver:
    add -4, r3              ; allocate space for va_list
    addi 0, r3, r10         ; r10 = address of va_list
    addi 4, r3, r11         ; r11 = address of varargs area
    st.w r11, 0[r10]        ; va_list = &varargs
    mov r6, r10             ; return first arg
    add 4, r3               ; deallocate
    jmp [r31]
```

**Status:** Implemented

---

## 10. Target-Specific Intrinsics

### 10.1 Memory Barriers [IMPLEMENTED]

**Intrinsics:**
- `__builtin_v850_synci()`
- `__builtin_v850_synce()`
- `__builtin_v850_syncm()`
- `__builtin_v850_syncp()`

**Status:** Fully implemented

---

### 10.2 System Register Access [IMPLEMENTED]

**Intrinsics:**
- `__builtin_v850_ldsr()`
- `__builtin_v850_stsr()`

**Status:** Fully implemented

---

### 10.3 Interrupt Control [IMPLEMENTED]

**Intrinsics:**
- `__builtin_v850_di()`
- `__builtin_v850_ei()`
- `__builtin_v850_halt()`
- `__builtin_v850_nop()`

**Status:** Fully implemented

---

### 10.4 MAC Operations [IMPLEMENTED]

**Intrinsics:**
- `__builtin_v850_mac()`
- `__builtin_v850_macu()`

**Requirements:** V850E1 or later

**Status:** Fully implemented

---

### 10.5 Saturating Arithmetic Intrinsics [IMPLEMENTED]

**Intrinsics:**
- `__builtin_v850_satadd()` - Saturating add (Base V850)
- `__builtin_v850_satsub()` - Saturating subtract (Base V850)
- `__builtin_v850_satsubr()` - Saturating subtract reverse (Base V850)
- `__builtin_v850_satadd3()` - 3-operand saturating add (V850E2+)
- `__builtin_v850_satsub3()` - 3-operand saturating subtract (V850E2+)

**Implementation Details:**
- Defined in `BuiltinsV850.def` and `IntrinsicsV850.td`
- CodeGen in `V850.cpp`, patterns in `V850InstrInfo.td`

**Status:** Fully implemented

---

### 10.6 Bit Search Intrinsics [IMPLEMENTED]

**Intrinsics:**
- `__builtin_v850_sch1l()` - Search for leftmost 1 (count leading zeros)
- `__builtin_v850_sch1r()` - Search for rightmost 1 (count trailing zeros)
- `__builtin_v850_sch0l()` - Search for leftmost 0 (count leading ones)
- `__builtin_v850_sch0r()` - Search for rightmost 0 (count trailing ones)

**Requirements:** V850E2+ or later

**Implementation Details:**
- Defined in `BuiltinsV850.def` and `IntrinsicsV850.td`
- Patterns in `V850InstrInfo.td` lines 1593-1597
- Also integrates with ISD::CTLZ/CTTZ via pattern matching

**Status:** Fully implemented

---

### 10.7 Cache Control Intrinsics [PARTIAL]

**Intrinsics:**
- `__builtin_v850_cache()` - Cache operations (TODO)
- `__builtin_v850_pref()` - Prefetch hint (TODO)

**Instruction Status:** IMPLEMENTED in `V850InstrInfo.td`
- CACHE instruction with 7-bit cacheop encoding (G3M+)
- PREF instruction for prefetch hint (G3M+)

**Intrinsic Status:** TODO - Clang builtins not yet implemented

**Requirements:** RH850G3M or later

**Priority:** Low

---

## Implementation Priority Summary

### Completed
1. ~~DIVQ/DIVQU Quick Division (2.5)~~ - DONE
2. ~~Bit Search Intrinsics (10.6)~~ - DONE
3. ~~SCH Search Operations (2.11)~~ - DONE
4. ~~HSH/HSW Half-word Swap (2.10)~~ - DONE
5. ~~Saturating Arithmetic (2.12)~~ - DONE
6. ~~Saturating Arithmetic Intrinsics (10.5)~~ - DONE
7. ~~If Conversion (1.6)~~ - DONE (EarlyIfConversion with CMOV)
8. ~~GP-Relative Addressing (8.2)~~ - DONE (V850TargetObjectFile, .sdata/.sbss)
9. ~~Peephole Optimizer (1.5)~~ - DONE (MOV+ADD folding, redundant ANDI removal, copy propagation)
10. ~~Post-RA Scheduler (1.7)~~ - DONE (anti-dependency breaking, dual-issue optimization)
11. ~~SASF Shift-and-Add (2.9)~~ - DONE (DAG combine for (shl x, 1) | setcc pattern)
12. ~~Callee-Saved Register Shrink Wrapping (3.3)~~ - DONE (enableShrinkWrapping, RET fix)
13. ~~Constant Materialization (5.4)~~ - DONE (MOVHI-only for zero low bits)
14. ~~Literal Pool / Constant Pool Support (5.2)~~ - DONE (FP constant handling, LDW_F/STW_F)
15. ~~Function Alignment Optimization (5.3)~~ - DONE (2-byte min, 4-byte preferred)
16. ~~SIMD-like Operations (7.2)~~ - DONE (BSH for bswap16, FMA patterns fixed)
17. ~~FP Constant Folding (7.3)~~ - DONE (LLVM infrastructure, IEEE 754 compliant)
18. ~~Varargs Support (9.3)~~ - DONE (V850MachineFunctionInfo, LowerVASTART, fixed CALL ISel)
19. ~~ADF/SBF 64-bit Arithmetic (2.3)~~ - DONE (ADDC/ADDE→ADF, SUBC/SUBE→SBF for V850E2+)
20. ~~Atomic Load/Store/Fence (1.4)~~ - DONE (custom lowering, shouldInsertFencesForAtomic, SYNCP fences)
21. ~~RH850G3M Scheduling (4.4)~~ - DONE (faster div/FPU, branch prediction, G3M-specific instructions)
22. ~~f64 CodeGen — DPR register class, ISel patterns, calling convention~~ - DONE (ADDFD/SUBFD/etc., CMOV_F64 pseudo, D6/D8/D10 ABI)

### High Priority (Next Phase)
- None currently queued

### Medium Priority
- f64 scheduling rules (V850SchedV850E2M.td, V850SchedRH850G3M.td) — latencies for ADDFD/MULFD/DIVFD/SQRTFD

### Hardware Limitations (Requires RH850 Backend)
1. Post-Increment Addressing (6.2) - RH850 only, not available on V850E2M

### Low Priority / Future
1. RH850G4MH Scheduling (4.5)
2. f64 rounding intrinsics (CEILF.D*, FLOORF.D*, ROUNDF.D*)
3. Hardware Loop Support (6.1)
4. Loop Strength Reduction (6.3)
5. Memory Barrier Optimization (8.3)
6. Cache Control Intrinsics (10.7)

---

## Appendix A: Optimization Dependencies

```
                    ┌─────────────────┐
                    │ Scheduling      │
                    │ Models          │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
       ┌──────────┐   ┌──────────┐   ┌──────────┐
       │ V850     │   │ V850E1   │   │ V850E2M  │
       │ Base     │   │          │   │ Dual-Issue│
       └──────────┘   └──────────┘   └──────────┘

                    ┌─────────────────┐
                    │ Frame           │
                    │ Optimization    │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
       ┌──────────┐   ┌──────────┐   ┌──────────┐
       │ PREPARE/ │   │ Tail     │   │ Shrink   │
       │ DISPOSE  │   │ Call     │   │ Wrapping │
       └──────────┘   └──────────┘   └──────────┘

                    ┌─────────────────┐
                    │ Memory          │
                    │ Optimization    │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
       ┌──────────┐   ┌──────────┐   ┌──────────┐
       │ EP-      │   │ GP-      │   │ Post-    │
       │ Relative │   │ Relative │   │ Increment│
       └──────────┘   └──────────┘   └──────────┘
```

---

## Appendix B: Test Coverage Requirements

Each optimization should have:

1. **Unit tests** - Test the pass in isolation
2. **CodeGen tests** - Verify correct instruction selection
3. **Performance tests** - Measure improvement on benchmarks
4. **Regression tests** - Ensure no code quality regressions

Test locations:
- `llvm/test/CodeGen/V850/` - CodeGen tests
- `llvm/test/MC/V850/` - Assembly/disassembly tests
- `clang/test/CodeGen/V850/` - Clang integration tests

---

## Appendix C: Benchmarks for Optimization Validation

Recommended benchmarks:
1. **Dhrystone** - Integer performance
2. **Whetstone** - Floating-point performance (V850E2M)
3. **CoreMark** - Embedded workload
4. **EEMBC** - Automotive benchmarks

Metrics to track:
- Code size (bytes)
- Cycle count (simulation)
- Stack usage
- Register pressure

---

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2026-03-01 | 1.8 | f64 CodeGen complete: DPR register class, FADD/FSUB/FMUL/FDIV/FABS/FNEG/FSQRT/FMINNUM/FMAXNUM Legal, CVTFDS/CVTFSD/CVTFWD/TRNCFDW patterns, CMOV_F64 pseudo (SELECT_CC f64 via split CMOVr), LD_DW_F/ST_DW_F for G3M f64 memory, f64 calling convention (D6/D8 args, D10 return), setTruncStoreAction/setLoadExtAction for f32↔f64 interop. f64 scheduling rules remain TODO. |
| 2026-02-11 | 1.7 | Added atomic load/store/fence custom lowering (SYNCP fences, shouldInsertFencesForAtomic, MaxAtomicInlineWidth) |
| 2026-02-11 | 1.6 | Added RH850G3M scheduling model (faster div/FPU, branch prediction, G3M-specific instructions) |
| 2026-02-07 | 1.5 | Added ADF/SBF 64-bit arithmetic (efficient ADDC/ADDE/SUBC/SUBE for V850E2+) |
| 2026-01-21 | 1.4 | Added Post-RA Scheduler implementation (anti-dependency breaking, dual-issue optimization) |
| 2026-01-21 | 1.3 | Added Peephole Optimizer implementation (MOV+ADD folding, ANDI removal, copy propagation) |
| 2026-01-21 | 1.2 | Added If Conversion (CMOV) and GP-Relative Addressing implementations |
| 2026-01-21 | 1.1 | Updated status: DIVQ/DIVQU, SCH search, HSH/HSW, saturating arithmetic all implemented |
| 2026-01-17 | 1.0 | Initial version with implemented optimizations audit |
