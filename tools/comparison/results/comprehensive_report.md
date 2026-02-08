# V850 LLVM vs CCRH Comprehensive Comparison Report

Generated: 2026-02-08 07:38:37

## Executive Summary

| Metric | LLVM | CCRH | LLVM/CCRH |
|--------|------|------|-----------|
| Total Instructions | 3118 | 5137 | 60% |
| Estimated Cycles | 4406 | 6529 | 67% |

**Overall: LLVM wins 7/8 benchmarks**

## Benchmark Comparison

| Benchmark | LLVM Insns | CCRH Insns | Insn% | LLVM Cycles | CCRH Cycles | Cycle% | Winner |
|-----------|------------|------------|-------|-------------|-------------|--------|--------|
| arithmetic | 248 | 265 | 94% | 459 | 490 | 94% | LLVM |
| bitwise | 351 | 350 | 100% | 502 | 497 | 101% | CCRH |
| control_flow | 259 | 428 | 61% | 430 | 690 | 62% | LLVM |
| crypto | 647 | 975 | 66% | 718 | 1082 | 66% | LLVM |
| dsp | 313 | 1042 | 30% | 491 | 1255 | 39% | LLVM |
| embedded | 530 | 817 | 65% | 692 | 987 | 70% | LLVM |
| matrix | 580 | 1011 | 57% | 737 | 1105 | 67% | LLVM |
| state_machine | 190 | 249 | 76% | 377 | 423 | 89% | LLVM |
| **TOTAL** | **3118** | **5137** | **60%** | **4406** | **6529** | **67%** | **LLVM** |

## Key Findings

### LLVM Advantages

- **dsp**: 39% of CCRH cycles (491 vs 1255)
- **control_flow**: 62% of CCRH cycles (430 vs 690)
- **crypto**: 66% of CCRH cycles (718 vs 1082)
- **matrix**: 67% of CCRH cycles (737 vs 1105)
- **embedded**: 70% of CCRH cycles (692 vs 987)
- **state_machine**: 89% of CCRH cycles (377 vs 423)

### Areas Where CCRH is Competitive

- **bitwise**: 101% of CCRH cycles
- **arithmetic**: 94% of CCRH cycles

---

*Note: Cycle estimates are based on V850E2M instruction timing. CCRH was compiled with -Ospeed (aggressive speed optimization), LLVM with -O2.*