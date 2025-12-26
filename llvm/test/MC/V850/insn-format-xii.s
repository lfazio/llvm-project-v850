// RUN: llvm-tblgen --gen-instr-info -I %p/../../../lib/Target/V850 \
// RUN:     -I %p/../../../include %p/../../../lib/Target/V850/V850.td \
// RUN:     | FileCheck %s

// Test Format XII (32-bit extended 2-operand) instruction definitions

// Byte/halfword swap instructions (Format XII)
// CHECK-DAG: BSW
// CHECK-DAG: BSH
// CHECK-DAG: HSW

// V850E2 halfword swap halfword
// CHECK-DAG: HSH

// Conditional move with immediate (Format XII)
// CHECK-DAG: CMOVi
