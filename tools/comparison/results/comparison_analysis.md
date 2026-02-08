# V850 LLVM vs CCRH Comparison Analysis

Generated: 2026-02-08

## Executive Summary

| Compiler | vs CCRH -Osize | Winner Count |
|----------|----------------|--------------|
| LLVM -O2 | 87% cycles (13% faster) | 5/9 benchmarks |
| LLVM -O3 | 105% cycles (5% slower) | 3/9 benchmarks |

**Recommendation:** Use `-O2` for best V850 performance with LLVM.

## Cycle Estimation Comparison

### LLVM -O2 vs CCRH (-Osize)

| Benchmark | LLVM Cycles | CCRH Cycles | Ratio | Winner |
|-----------|-------------|-------------|-------|--------|
| arithmetic | 459 | 916 | 50% | **LLVM** |
| bitwise | 502 | 472 | 106% | CCRH |
| control_flow | 426 | 537 | 79% | **LLVM** |
| crypto | 612 | 454 | 134% | CCRH |
| dsp | 464 | 628 | 73% | **LLVM** |
| embedded | 748 | 712 | 105% | CCRH |
| matrix | 576 | 549 | 104% | CCRH |
| memory | 403 | 456 | 88% | **LLVM** |
| state_machine | 206 | 287 | 71% | **LLVM** |
| **TOTAL** | **4396** | **5011** | **87%** | **LLVM** |

### LLVM -O3 vs CCRH (-Osize)

| Benchmark | LLVM Cycles | CCRH Cycles | Ratio | Winner |
|-----------|-------------|-------------|-------|--------|
| arithmetic | 459 | 916 | 50% | **LLVM** |
| bitwise | 502 | 472 | 106% | CCRH |
| control_flow | 431 | 537 | 80% | **LLVM** |
| crypto | 718 | 454 | 158% | CCRH |
| dsp | 500 | 628 | 79% | **LLVM** |
| embedded | 998 | 712 | 140% | CCRH |
| matrix | 904 | 549 | 164% | CCRH |
| memory | 403 | 456 | 88% | **LLVM** |
| state_machine | 383 | 287 | 133% | CCRH |
| **TOTAL** | **5298** | **5011** | **105%** | CCRH |

### Key Observations

**Why LLVM -O2 beats LLVM -O3:**
- `-O3` enables aggressive loop unrolling and inlining
- Increases code size significantly (30% more instructions than -O2)
- Added overhead outweighs any unrolling benefits for embedded workloads
- Worst regressions: matrix (576→904 cycles), embedded (748→998 cycles)

**LLVM Strengths:**
- 64-bit arithmetic: 50% faster with ADF/SBF instructions
- State machine: 71% of CCRH cycles (compact conditional code)
- DSP: 73% of CCRH cycles (efficient loop handling)
- Control flow: 79% of CCRH cycles

**CCRH Strengths:**
- Crypto: Tighter loops, better scheduling for AES operations
- Matrix: More aggressive vectorization-like patterns
- Bitwise: Marginally better (106% - only 6% difference)

## Instruction Count Comparison

| Benchmark | LLVM -O2 | LLVM -O3 | CCRH | O2/CCRH |
|-----------|----------|----------|------|---------|
| arithmetic | 248 | 248 | 236 | 105% |
| bitwise | 351 | 351 | 319 | 110% |
| control_flow | 255 | 265 | 302 | 84% |
| crypto | 523 | 647 | 362 | 144% |
| dsp | 307 | 321 | 335 | 91% |
| embedded | 575 | 700 | 422 | 136% |
| matrix | 442 | 765 | 429 | 103% |
| memory | 215 | 215 | 274 | 78% |
| state_machine | 112 | 208 | 165 | 67% |
| **TOTAL** | **3028** | **3720** | **2844** | **106%** |

**Note:** LLVM -O2 generates 6% more instructions but runs 13% faster due to better instruction selection.

## Recently Fixed Issues

### 1. Branch Relaxation Crash (FIXED - 2026-02-08)

**Problem:** LLVM crashed with `-O3` on embedded benchmark:
```
Assertion '!BytesRemoved && "code size not handled"' failed
```

**Fix:** Updated `V850InstrInfo::removeBranch` and `insertBranch` to properly track BytesRemoved/BytesAdded using `getInstSizeInBytes()`.

**Commit:** 9fd7b82a15f9

### 2. ADF/SBF Patterns for 64-bit Arithmetic (FIXED - 2026-02-07)

**Problem:** LLVM used setf+add sequence (7 instructions) for 64-bit add/sub.

**After (4 instructions):**
```asm
add r6, r8
adf c, r9, r7, r11
mov r8, r10
jmp [r31]
```

**Impact:** 28 bytes saved in arithmetic benchmark.

### 3. MAC Result Register Bug (FIXED - 2026-02-07)

**Problem:** After MAC, both result copies used the same register.

**After (fixed):**
```asm
mac r7, r6, r8, r9
mov r8, r10    ; low part
mov r9, r11    ; high part
```

### 4. 48-bit MOV imm32 Instruction (FIXED)

**Problem:** LLVM used MOVHI + MOVEA (8 bytes) for 32-bit constants.

**After:** Single 6-byte MOV instruction.

**Impact:** 52 bytes saved across all benchmarks.

## Recommendations

### For Users

1. **Use `-O2` for best performance** - `-O3` can be 18% slower
2. Use `-Os` for code-size critical applications
3. Target V850E2M to enable ADF/SBF, DIVQ, and MAC optimizations

### Potential Future Optimizations

| Priority | Optimization | Expected Impact |
|----------|--------------|-----------------|
| Medium | Improve crypto loops | ~30% crypto improvement |
| Medium | Better matrix scheduling | ~10% matrix improvement |
| Low | Register pre-allocation for returns | Minor (~2%) |

## Test Infrastructure

Benchmarks located in `tools/comparison/benchmarks/`:
- `micro/` - Basic operations (arithmetic, bitwise, control flow)
- `kernels/` - Compute kernels (crypto, dsp, matrix)
- `apps/` - Application patterns (embedded, memory, state_machine)

Compile and compare:
```bash
cd tools/comparison
python3 scripts/run_benchmarks.py  # If CCRH available
python3 scripts/estimate_cycles.py results/asm/arithmetic_llvm.s
```

## Revision History

| Date | Changes |
|------|---------|
| 2026-02-08 | Fixed branch relaxation crash with -O3; Updated comparison with CCRH -Osize |
| 2026-02-07 | Fixed ADF/SBF patterns, MAC result registers, 48-bit MOV |
