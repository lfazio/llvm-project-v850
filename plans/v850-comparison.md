# V850 Compiler Comparison Plan: LLVM/Clang vs CCRH (Renesas)

## Objective

Compare code generation quality between LLVM/Clang V850 backend and Renesas CCRH compiler across multiple dimensions: correctness, performance, and code size. Use CCRH as a reference to validate our implementation and identify optimization opportunities.

**Note**: Binary compatibility with CCRH is not a goal. The focus is on learning from CCRH's code generation to improve our own implementation.

---

## 1. Test Infrastructure Setup

### 1.1 Directory Structure
```
tools/comparison/
├── benchmarks/           # Benchmark source files
│   ├── micro/            # Micro-benchmarks (single operations)
│   ├── kernels/          # Computational kernels
│   └── apps/             # Small application benchmarks
├── scripts/
│   ├── compile_ccrh.sh   # Build with CCRH
│   ├── compile_llvm.sh   # Build with LLVM/Clang
│   ├── compare_asm.py    # Assembly comparison tool
│   ├── compare_obj.py    # Object file comparison tool
│   ├── analyze_size.py   # Code size analysis
│   └── run_metrics.py    # Collect all metrics
├── results/              # Comparison results
│   ├── asm/              # Assembly diffs
│   ├── obj/              # Object analysis
│   └── reports/          # Summary reports
└── README.md
```

### 1.2 Build Configuration
- **CCRH**: Document compiler version, flags, and optimization levels
- **LLVM/Clang**: Use matching optimization levels (-O0, -O1, -O2, -O3, -Os, -Oz)
- **Target CPU**: Test across v850, v850e1, v850e2m variants

---

## 2. Comparison Categories

### 2.1 Assembly Output Comparison

#### A. Instruction Selection
- [ ] Compare instruction choices for common operations
- [ ] Identify LLVM-specific vs CCRH-specific patterns
- [ ] Document instruction encoding differences

#### B. Register Allocation
- [ ] Compare register usage patterns
- [ ] Analyze spill/reload frequency
- [ ] Check callee-saved register handling

#### C. Code Patterns
- [ ] Function prologue/epilogue comparison
- [ ] Loop constructs (for, while, do-while)
- [ ] Switch/case lowering (jump tables vs cascaded branches)
- [ ] Conditional expressions
- [ ] Arithmetic operations (especially multiply/divide)
- [ ] Bitfield operations
- [ ] Structure access patterns

#### D. Calling Convention
- [ ] Argument passing (registers vs stack)
- [ ] Return value handling
- [ ] Variadic function support
- [ ] Stack frame layout

### 2.2 Object File Comparison

#### A. Section Layout
- [ ] .text section size and alignment
- [ ] .data section organization
- [ ] .bss section handling
- [ ] .rodata placement

#### B. Symbol Table
- [ ] Symbol naming conventions
- [ ] Symbol visibility
- [ ] Weak symbol handling

#### C. Relocation Types
- [ ] Compare relocation entries
- [ ] Verify relocation correctness
- [ ] Document any unsupported relocations

### 2.3 ELF Binary Comparison

#### A. Header Analysis
- [ ] ELF header fields comparison
- [ ] Program header differences
- [ ] Section header comparison

#### B. Debug Information
- [ ] DWARF format correctness
- [ ] Line number information accuracy
- [ ] Variable location tracking

---

## 3. Metrics Collection

### 3.1 Code Size Metrics

| Metric | Description |
|--------|-------------|
| Total .text size | Overall code section size |
| Per-function size | Individual function sizes |
| Instruction count | Number of instructions generated |
| NOP/padding count | Alignment overhead |
| Literal pool size | Constant data in code |

### 3.2 Performance Metrics (Static Analysis)

| Metric | Description |
|--------|-------------|
| Instruction mix | Distribution of instruction types |
| Branch density | Branches per instruction |
| Memory operations | Load/store frequency |
| Critical path length | Estimated latency chains |
| Loop overhead | Instructions per iteration overhead |

### 3.3 Cycle Count Estimation

Use V850 cycle timing information (docs/V850CycleTimings.md) to estimate:
- [ ] Function execution cycles
- [ ] Loop iteration cycles
- [ ] Memory access patterns impact

---

## 4. Benchmark Suite

### 4.1 Micro-benchmarks

```c
// Integer arithmetic
int add_test(int a, int b);
int mul_test(int a, int b);
int div_test(int a, int b);
unsigned udiv_test(unsigned a, unsigned b);

// Bitwise operations
int shift_test(int a, int n);
int bitfield_extract(int val, int pos, int width);
int bitfield_insert(int val, int bits, int pos, int width);

// Memory operations
void memcpy_test(void *dst, const void *src, size_t n);
void memset_test(void *dst, int val, size_t n);

// Control flow
int switch_test(int x);
int loop_test(int n);
int recursive_test(int n);
```

### 4.2 Computational Kernels

```c
// DSP-like operations
int fir_filter(const int *coeffs, const int *samples, int n);
int iir_filter(int input, int *state);
void matrix_multiply(int *c, const int *a, const int *b, int n);

// Bit manipulation
int popcount(unsigned x);
int clz(unsigned x);
int ctz(unsigned x);
unsigned bitrev(unsigned x);

// Cryptographic primitives
void aes_sbox(unsigned char *state);
unsigned crc32(const unsigned char *data, size_t len);
```

### 4.3 Application Benchmarks

```c
// Embedded typical workloads
void state_machine(int event);
void interrupt_handler(void);
void timer_callback(void);
void can_message_process(const uint8_t *msg);
```

---

## 5. Validation Using CCRH as Reference

### 5.1 Instruction Encoding Verification

Verify LLVM instruction encodings are correct by comparing against CCRH output:
1. Compile identical source with both compilers
2. Disassemble both outputs
3. When same instruction is chosen, verify encoding matches
4. Use CCRH as ground truth for correct machine code

```bash
# Example workflow
ccrh -cpu=v850e2m -c test.c -o test_ccrh.o
clang --target=v850 -mcpu=v850e2m -c test.c -o test_llvm.o

# Disassemble and compare
objdump -d test_ccrh.o > test_ccrh.s
llvm-objdump -d test_llvm.o > test_llvm.s

# Compare encodings
python scripts/compare_encodings.py test_ccrh.s test_llvm.s
```

### 5.2 Correctness Verification

- [ ] Run LLVM-compiled binaries on simulator/emulator
- [ ] Compare execution results against expected output
- [ ] Use CCRH output as reference when debugging issues
- [ ] Verify corner cases (overflow, edge conditions)

### 5.3 Learning from CCRH

Document interesting patterns and techniques from CCRH:

| Pattern | CCRH Approach | Potential LLVM Improvement |
|---------|---------------|---------------------------|
| Loop optimization | ... | ... |
| Constant loading | ... | ... |
| Function calls | ... | ... |

---

## 6. Reporting

### 6.1 Summary Report Format

```markdown
# V850 Compiler Comparison Report

## Executive Summary
- Overall code size: LLVM vs CCRH (percentage)
- Instruction count: LLVM vs CCRH
- Estimated performance: LLVM vs CCRH

## Detailed Results

### Code Size by Optimization Level
| Level | CCRH | LLVM | Difference |
|-------|------|------|------------|
| -O0   | ...  | ...  | ...        |
| -O2   | ...  | ...  | ...        |
| -Os   | ...  | ...  | ...        |

### Per-Benchmark Analysis
[Detailed tables per benchmark]

### Instruction Selection Differences
[Notable instruction choice differences]

### Recommendations
[Areas for improvement in LLVM backend]
```

### 6.2 Issue Tracking

Track discovered issues in categories:
- **Correctness**: Wrong code generation
- **Performance**: Suboptimal instruction selection
- **Size**: Unnecessary code bloat
- **Missing features**: Instructions/patterns not yet implemented

---

## 7. Implementation Tasks

### Phase 1: Setup (Foundation) [COMPLETE]
- [x] Create directory structure
- [x] Write compilation scripts for CCRH and LLVM
- [x] Implement basic assembly comparison tool
- [x] Set up test harness (run_benchmarks.py)

### Phase 2: Micro-benchmarks [COMPLETE]
- [x] Implement all micro-benchmarks
  - arithmetic.c - Integer arithmetic operations
  - bitwise.c - Bitwise and bit manipulation
  - control_flow.c - Branching, loops, switch
  - memory.c - Load/store patterns
- [x] Compile with LLVM (CCRH requires commercial license)
- [x] Generate initial comparison data
- [x] Document first findings (comparison_analysis.md)

### Phase 3: Analysis Tools [PARTIAL]
- [ ] Implement object file analyzer
- [ ] Create encoding comparison script
- [ ] Build cycle estimation tool
- [x] Generate automated reports (compare_asm.py)

### Phase 4: Kernel Benchmarks [COMPLETE]
- [x] Implement computational kernels
  - dsp.c - DSP algorithms (FIR, IIR, convolution)
  - matrix.c - Matrix operations
  - crypto.c - Cryptographic primitives (CRC, AES, XTEA)
- [x] Run full comparison suite (LLVM only)
- [x] Identify optimization opportunities (ADF/SBF, MOVi32 - now fixed)
- [x] Document LLVM backend improvements needed (comparison_analysis.md)

### Phase 4.5: Application Benchmarks [COMPLETE]
- [x] Implement application benchmarks
  - state_machine.c - State machine patterns (table-driven, switch, function pointer)
  - embedded.c - Embedded patterns (ring buffer, CAN, PID, timers)

### Phase 5: Validation
- [ ] Set up simulator/emulator testing
- [ ] Verify correctness of generated code
- [ ] Complete encoding verification against CCRH
- [ ] Document optimization opportunities learned from CCRH

### Phase 6: Reporting and Improvement
- [ ] Generate comprehensive comparison report
- [ ] Document all findings and lessons learned
- [ ] Create prioritized improvement list for LLVM backend
- [ ] Implement identified optimizations

---

## 8. Tools and Dependencies

### Required Tools
- **CCRH**: Renesas CC-RH compiler (commercial license required)
- **LLVM/Clang**: Built V850 backend
- **Python 3**: For analysis scripts
- **objdump/llvm-objdump**: Disassembly
- **readelf/llvm-readelf**: ELF analysis
- **diff tools**: For text comparison

### Optional Tools
- **V850 simulator**: For execution verification
- **Renesas debugger**: For detailed analysis
- **Perf analysis tools**: Cycle-accurate simulation

---

## 9. Success Criteria

### Minimum Goals
- [ ] All micro-benchmarks produce correct code
- [ ] Code size within 20% of CCRH at -Os
- [ ] No instruction encoding errors
- [ ] Understand performance differences

### Stretch Goals
- [ ] Code size within 10% of CCRH
- [ ] Match or exceed CCRH performance estimates
- [ ] Support equivalent intrinsics functionality

### Optional (Nice-to-Have)
- [ ] Binary compatibility with CCRH objects
- [ ] ABI compatibility for linking mixed objects
- [ ] Identical output for specific test cases

---

## 10. References

- [V850 ISA Reference](V850InstructionReference.md)
- [V850 Cycle Timings](V850CycleTimings.md)
- [CCRH User Manual](https://www.renesas.com/documentation)
- [V850 ABI Specification](https://www.renesas.com/documentation)
