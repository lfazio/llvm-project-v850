// RUN: llvm-tblgen --gen-instr-info -I %p/../../../lib/Target/V850 \
// RUN:     -I %p/../../../include %p/../../../lib/Target/V850/V850.td \
// RUN:     | FileCheck %s

// Test Format III (Conditional Branch, 16-bit) instruction definitions

// CHECK-DAG: BV
// CHECK-DAG: BC
// CHECK-DAG: BZ
// CHECK-DAG: BNH
// CHECK-DAG: BN
// CHECK-DAG: BR
// CHECK-DAG: BLT
// CHECK-DAG: BLE
// CHECK-DAG: BNV
// CHECK-DAG: BNC
// CHECK-DAG: BNZ
// CHECK-DAG: BH
// CHECK-DAG: BP
// CHECK-DAG: BSA
// CHECK-DAG: BGE
// CHECK-DAG: BGT

