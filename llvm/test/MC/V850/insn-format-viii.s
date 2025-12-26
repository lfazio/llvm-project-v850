// RUN: llvm-tblgen --gen-instr-info -I %p/../../../lib/Target/V850 \
// RUN:     -I %p/../../../include %p/../../../lib/Target/V850/V850.td \
// RUN:     | FileCheck %s

// Test Format VIII (Bit Manipulation, 32-bit) instruction definitions
// These operate on memory bits with base+displacement addressing

// CHECK-DAG: SET1
// CHECK-DAG: NOT1
// CHECK-DAG: CLR1
// CHECK-DAG: TST1

