// RUN: llvm-tblgen --gen-instr-info -I %p/../../../lib/Target/V850 \
// RUN:     -I %p/../../../include %p/../../../lib/Target/V850/V850.td \
// RUN:     | FileCheck %s

// Test Format I (Register-Register, 16-bit) instruction definitions

// CHECK-DAG: ADD
// CHECK-DAG: SUB
// CHECK-DAG: SUBR
// CHECK-DAG: CMP
// CHECK-DAG: MOV
// CHECK-DAG: NOT
// CHECK-DAG: DIVH
// CHECK-DAG: JMP
// CHECK-DAG: SATSUBR
// CHECK-DAG: SATSUB
// CHECK-DAG: SATADD
// CHECK-DAG: MULH
// CHECK-DAG: OR
// CHECK-DAG: XOR
// CHECK-DAG: AND
// CHECK-DAG: TST

