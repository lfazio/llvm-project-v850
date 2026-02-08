# V850 LLVM vs CCRH Comparison Analysis

Generated: 2026-02-08

## Summary

| Metric | LLVM | CCRH | LLVM/CCRH Ratio |
|--------|------|------|-----------------|
| Total code size | 26072 bytes | 47352 bytes | 55% |
| Total instructions | 3118 | 5137 | 60% |
| Estimated cycles | 4406 | 6529 | 67% |
| Benchmarks passed | 9/9 | 8/9 | - |

**LLVM outperforms CCRH** in both code size (55%) and estimated performance (67%).

## Cycle Estimation Comparison

Static cycle estimation using V850E2M instruction timing data:

| Benchmark | LLVM Insns | CCRH Insns | Ratio | LLVM Cycles | CCRH Cycles | Ratio | Winner |
|-----------|------------|------------|-------|-------------|-------------|-------|--------|
| arithmetic | 248 | 265 | 93% | 459 | 490 | 93% | LLVM |
| bitwise | 351 | 350 | 100% | 502 | 497 | 101% | CCRH |
| control_flow | 259 | 428 | 60% | 430 | 690 | 62% | LLVM |
| crypto | 647 | 975 | 66% | 718 | 1082 | 66% | LLVM |
| dsp | 313 | 1042 | 30% | 491 | 1255 | 39% | LLVM |
| embedded | 530 | 817 | 64% | 692 | 987 | 70% | LLVM |
| matrix | 580 | 1011 | 57% | 737 | 1105 | 66% | LLVM |
| state_machine | 190 | 249 | 76% | 377 | 423 | 89% | LLVM |
| **TOTAL** | **3118** | **5137** | **60%** | **4406** | **6529** | **67%** | **LLVM** |

**Key Observations:**
- LLVM wins 7 out of 8 benchmarks (CCRH wins only bitwise by 1%)
- DSP benchmark shows LLVM generating only 30% of CCRH's instructions
- Control flow and crypto show significant LLVM advantages (62-66%)
- Bitwise is the only benchmark where CCRH is marginally better

**Note on CCRH Optimization:**
- CCRH was compiled with `-Ospeed` (speed optimization)
- CCRH aggressively unrolls loops (4x in FIR filter) and uses LOOP instruction
- This increases code size significantly but may improve runtime performance
- LLVM generates more compact scalar loops, better for code size

**DSP Benchmark Deep Dive:**
- CCRH's fir_filter: 4x loop unrolling with LOOP instruction (67 lines)
- LLVM's fir_filter: Compact scalar loop (14 lines)
- Real-world performance depends on loop iteration count

**Bitwise Benchmark Analysis:**
- CCRH is marginally better (497 vs 502 cycles, 1% difference)
- CLZ/CTZ: CCRH generates slightly better code (36 vs 40-42 insns)
- Both compilers use CMOV-based expansion for manual CLZ/CTZ implementations
- Note: Benchmark uses manual bit-counting code, not `__builtin_clz`/`__builtin_ctz`
- With builtins, LLVM would emit single SCH1L/SCH1R instructions (V850E2+)

## Recently Fixed Issues

### 1. ADF/SBF Patterns for 64-bit Arithmetic (FIXED - 2026-02-07)

**Problem:** LLVM was using setf+add sequence (7 instructions) for 64-bit add/sub instead of ADF/SBF.

**Fix:** Added ADDC/ADDE/SUBC/SUBE as Legal on V850E2+, with ISel patterns mapping to ADD/ADF/SUB/SBF.

**Before (7 instructions):**
```asm
add r7, r9
setf c, r10
add r6, r8
add r10, r9
mov r8, r10
mov r9, r11
jmp [r31]
```

**After (4 instructions):**
```asm
add r6, r8
adf c, r9, r7, r11
mov r8, r10
jmp [r31]
```

**Impact:** 28 bytes saved in arithmetic benchmark, 36 bytes total.

**Files Modified:**
- `llvm/lib/Target/V850/V850ISelLowering.cpp` - Added ADDC/ADDE as Legal, performADDECombine for MAC
- `llvm/lib/Target/V850/V850InstrInfo.td` - Added addc/adde/subc/sube patterns

### 2. MAC Result Register Bug (FIXED - 2026-02-07)

**Problem:** After MAC, both result copies were using the same register (r8) instead of low (r8) and high (r9).

**Before (buggy):**
```asm
mac r7, r6, r8, r9
mov r8, r10    ; low part - correct
mov r8, r11    ; BUG: should be mov r9, r11
jmp [r31]
```

**After (fixed):**
```asm
mac r7, r6, r8, r9
mov r8, r10    ; low part to r10
mov r9, r11    ; high part to r11
jmp [r31]
```

**Root Cause:** In `performADDECombine`, when replacing ADDE uses with MAC result 1, the return value wasn't being propagated correctly. The DAGCombiner infrastructure doesn't handle multi-result replacements properly via the return value.

**Fix:** Following ARM's pattern for SMLAL/UMLAL, we now explicitly call `ReplaceAllUsesOfValueWith` for BOTH the ADDC and ADDE results, then return the original node to tell the combiner we've handled it manually.

**Files Modified:**
- `llvm/lib/Target/V850/V850ISelLowering.cpp` - Fixed performADDECombine to use explicit replacements

### 3. i64 Return Calling Convention (FIXED)

**Problem:** LLVM was using sret (struct return) for i64 returns instead of r10:r11 registers.

**Root Cause:** On 32-bit targets, i64 is split into two i32 values before calling convention is applied. The CC only provided R10 for i32 returns, causing the second half to fail.

**Fix:** Changed `CCIfType<[i32], CCAssignToReg<[R10]>>` to `CCIfType<[i32], CCAssignToReg<[R10, R11]>>`.

**Impact:** ~130 bytes saved in arithmetic benchmark.

### 3. MOV imm32, reg1 Instruction (FIXED)

**Problem:** LLVM was using MOVHI + MOVEA (8 bytes) to load 32-bit constants.

**Root Cause:** The 48-bit MOV imm32 instruction (V850E1+) was not implemented.

**Fix:** Added FormatVI_E1 instruction format and MOVi32 instruction definition with proper pattern matching.

**Example - div_const3 (now identical to CCRH):**
```asm
; Both CCRH and LLVM now generate:
mov 1431655766, r10   ; 6 bytes, single instruction
```

**Impact:** 52 bytes saved across all benchmarks (2 bytes per 32-bit constant load).

## Current Code Generation Quality

### Functions with Optimal Code

Many functions now generate optimal or near-optimal code:
- **64-bit arithmetic**: add_i64, sub_i64 (now using ADF/SBF)
- **MAC instructions**: mac_i32, macu_i32 (single MAC instruction)
- **32-bit arithmetic**: add_i32, sub_i32, mul_i32 (2-3 instructions each)
- **Division**: div_i32, mod_i32 (3 instructions using DIVQ)
- **Bitwise operations**: and, or, xor, not
- **Sign/zero extensions**: SXB, SXH, ZXB, ZXH
- **32-bit constant loads**: Now using MOVi32 (6 bytes)

### Remaining Minor Inefficiencies

#### 1. Register Allocation for Return Values (LOW PRIORITY)

**Description:** Minor inefficiency in register movement for return values.

**Example - mul_i32_to_i64:**
```asm
; LLVM
mul r6, r7, r11   ; result in r7:r11
mov r7, r10       ; move low to r10

; CCRH
mov r7, r10       ; move r7 to r10 first
mul r6, r10, r11  ; result directly in r10:r11
```

Both are 3 instructions, but CCRH avoids post-multiply register movement.

## Benchmark Code Sizes

| Benchmark | Old (bytes) | New (bytes) | Savings |
|-----------|-------------|-------------|---------|
| arithmetic | 2792 | 2764 | 28 bytes |
| bitwise | 2680 | 2680 | 0 |
| control_flow | 2084 | 2084 | 0 |
| crypto | 4292 | 4292 | 0 |
| dsp | 1868 | 1860 | 8 bytes |
| embedded | 3260 | 3260 | 0 |
| matrix | 2828 | 2828 | 0 |
| memory | 3096 | 3096 | 0 |
| state_machine | 3208 | 3208 | 0 |
| **Total** | **26108** | **26072** | **36 bytes** |

## Recommendations

### Priority 1: Register Pre-allocation for Return Values (LOW PRIORITY)
- Minor optimization - pre-allocate r10:r11 for 64-bit multiply results
- Very low impact but would match CCRH pattern
- Could be addressed by improving register coalescing hints

## Files Modified (All Fixed Issues)

- `llvm/lib/Target/V850/V850CallingConv.td` - Fixed i64 return convention
- `llvm/lib/Target/V850/V850InstrFormats.td` - Added FormatVI_E1 class for 48-bit MOV
- `llvm/lib/Target/V850/V850InstrInfo.td` - Added MOVi32 instruction, ADF/SBF patterns
- `llvm/lib/Target/V850/V850ISelLowering.cpp` - Added ADDC/ADDE as Legal, performADDECombine
- `llvm/lib/Target/V850/Disassembler/V850Disassembler.cpp` - Added MOVi32 decoding
- `llvm/test/CodeGen/V850/const-materialization.ll` - Updated tests for MOVi32
- `llvm/test/CodeGen/V850/i64-add-sub.ll` - New test for ADF/SBF patterns
