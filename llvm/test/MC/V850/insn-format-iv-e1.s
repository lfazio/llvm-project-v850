// RUN: llvm-tblgen --gen-instr-info -I %p/../../../lib/Target/V850 \
// RUN:     -I %p/../../../include %p/../../../lib/Target/V850/V850.td \
// RUN:     | FileCheck %s

// Test Format IV-E1 (V850E1 Short Load Unsigned, 16-bit) instruction definitions
// These are V850E1+ extensions for unsigned short loads with EP base

// CHECK-DAG: SLDBU
// CHECK-DAG: SLDHU

