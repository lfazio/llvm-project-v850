# V850 Compiler Comparison Infrastructure

This directory contains benchmarks and tools for comparing code generation between LLVM/Clang and Renesas CC-RH (CCRH) compilers for the V850 architecture.

## Directory Structure

```
tools/comparison/
├── benchmarks/           # Benchmark source files
│   ├── micro/            # Micro-benchmarks (single operations)
│   │   ├── arithmetic.c  # Integer arithmetic operations
│   │   ├── bitwise.c     # Bitwise and bit manipulation
│   │   ├── control_flow.c# Branching, loops, switch
│   │   └── memory.c      # Load/store patterns
│   ├── kernels/          # Computational kernels
│   │   ├── dsp.c         # DSP algorithms (FIR, IIR, etc.)
│   │   ├── matrix.c      # Matrix operations
│   │   └── crypto.c      # Cryptographic primitives
│   └── apps/             # Application benchmarks
│       ├── state_machine.c # State machine patterns
│       └── embedded.c    # Embedded system patterns
├── scripts/
│   ├── compile_llvm.sh   # Build with LLVM/Clang
│   ├── compile_ccrh.sh   # Build with CC-RH
│   ├── compare_asm.py    # Assembly comparison tool
│   └── run_benchmarks.py # Run all benchmarks
├── results/              # Output directory (generated)
│   ├── asm/              # Assembly files
│   ├── obj/              # Object files
│   └── reports/          # Comparison reports
└── README.md             # This file
```

## Prerequisites

### LLVM/Clang

The V850 backend should be built. By default, scripts look for tools in:
```
/home/lfazio/Projects/llvm-project/build-v850/bin/
```

You can override with environment variables:
```bash
export CLANG=/path/to/clang
export LLC=/path/to/llc
export LLVM_OBJDUMP=/path/to/llvm-objdump
```

### CC-RH (Renesas)

Set the path to your CC-RH installation:
```bash
export CCRH_PATH=/opt/renesas/ccrh/V2.02.00
```

## Usage

### Quick Start

Run all benchmarks with LLVM only (no CCRH required):
```bash
cd tools/comparison
python scripts/run_benchmarks.py --llvm-only
```

### Full Comparison

With both compilers available:
```bash
python scripts/run_benchmarks.py
```

### Custom Options

```bash
# Different optimization level
python scripts/run_benchmarks.py -O3

# Different target CPU
python scripts/run_benchmarks.py --cpu=v850e1

# Custom output directory
python scripts/run_benchmarks.py -o /tmp/v850_results
```

### Individual Compilation

Compile a single file with LLVM:
```bash
./scripts/compile_llvm.sh -O2 -mcpu=v850e2m -S benchmarks/micro/arithmetic.c
```

Compile with CC-RH:
```bash
./scripts/compile_ccrh.sh -O2 -mcpu=v850e2m -S benchmarks/micro/arithmetic.c
```

### Assembly Comparison

Compare two assembly files:
```bash
python scripts/compare_asm.py arithmetic_llvm.s arithmetic_ccrh.s -o report.txt
```

## Benchmark Categories

### Micro-benchmarks

Small functions testing specific operations:

- **arithmetic.c**: Integer add, sub, mul, div, MAC, saturating ops
- **bitwise.c**: AND, OR, XOR, shifts, rotates, bit counting, byte swap
- **control_flow.c**: Conditionals, switches, loops, recursion
- **memory.c**: Load/store patterns, structure access, alignment

### Computational Kernels

Larger algorithms common in embedded systems:

- **dsp.c**: FIR/IIR filters, convolution, signal processing
- **matrix.c**: Matrix multiply, transpose, determinant
- **crypto.c**: CRC, AES primitives, XTEA, hash functions

### Application Benchmarks

Real-world embedded patterns:

- **state_machine.c**: Table-driven, switch-based, function pointer FSMs
- **embedded.c**: Ring buffers, CAN message parsing, PID control, timers

## Output Format

### Summary Report

The `summary.txt` file shows:
- Total code size per compiler
- Per-benchmark size comparison
- Size ratio (LLVM/CCRH)

### Per-Benchmark Reports

Each `*_comparison.txt` file includes:
- Function-by-function size comparison
- Instruction count differences
- Instruction mix analysis (arithmetic, memory, branch, etc.)

### JSON Results

Raw results in `results.json` for further processing.

## Interpreting Results

### Size Ratio

- `< 1.0`: LLVM generates smaller code
- `= 1.0`: Equal code size
- `> 1.0`: CCRH generates smaller code

### Instruction Mix

Differences in instruction categories may indicate:
- **More branches**: Less efficient control flow
- **More memory ops**: Register pressure issues
- **More moves**: Suboptimal register allocation

## Adding New Benchmarks

1. Create a `.c` file in the appropriate subdirectory
2. Use standard C (no compiler-specific extensions)
3. Avoid undefined behavior
4. Include multiple small functions for fine-grained analysis

Example template:
```c
/*
 * Benchmark: [Category] - [Description]
 */

#include <stdint.h>

/* Function 1 */
int test_operation1(int a, int b) {
    return a + b;
}

/* Function 2 */
void test_operation2(int *arr, int n) {
    for (int i = 0; i < n; i++) {
        arr[i] *= 2;
    }
}
```

## Known Limitations

1. **Instruction size estimation**: The comparison tool estimates instruction sizes; actual sizes may vary
2. **CCRH availability**: Full comparison requires CC-RH commercial license
3. **ABI differences**: Symbol naming conventions differ between compilers
4. **Optimization heuristics**: Compilers may make different trade-offs

## Related Documentation

- [V850 Comparison Plan](../../plans/v850-comparison.md)
- [V850 Optimization Plan](../../plans/v850-optimisation.md)
- [V850 ISA Reference](../../docs/V850InstructionReference.md)
