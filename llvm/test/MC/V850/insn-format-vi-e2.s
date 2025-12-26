// RUN: llvm-tblgen --gen-instr-info -I %p/../../../lib/Target/V850 \
// RUN:     -I %p/../../../include %p/../../../lib/Target/V850/V850.td \
// RUN:     | FileCheck %s

// Test Format VI-E2 (48-bit jump with 32-bit displacement) instruction definitions
// These instructions are V850E2+ only and use 32-bit PC-relative displacements

// Jump relative with 32-bit displacement
// CHECK-DAG: JR32

// Jump and register link with 32-bit displacement
// CHECK-DAG: JARL32

// Jump with 32-bit displacement (indirect with offset)
// CHECK-DAG: JMP32
