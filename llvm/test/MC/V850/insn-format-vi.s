// RUN: llvm-tblgen --gen-instr-info -I %p/../../../lib/Target/V850 \
// RUN:     -I %p/../../../include %p/../../../lib/Target/V850/V850.td \
// RUN:     | FileCheck %s

// Test Format VI (32-bit Three-Operand) instruction definitions

// CHECK-DAG: ADDI
// CHECK-DAG: MOVEA
// CHECK-DAG: MOVHI
// CHECK-DAG: SATSUBI
// CHECK-DAG: ORI
// CHECK-DAG: XORI
// CHECK-DAG: ANDI
// CHECK-DAG: MULHI

