// RUN: llvm-tblgen --gen-instr-info -I %p/../../../lib/Target/V850 \
// RUN:     -I %p/../../../include %p/../../../lib/Target/V850/V850.td \
// RUN:     | FileCheck %s

// Test Format VII (32-bit Load/Store with 16-bit displacement) instruction definitions

// Signed loads
// CHECK-DAG: LDB
// CHECK-DAG: LDH
// CHECK-DAG: LDW

// Stores
// CHECK-DAG: STB
// CHECK-DAG: STH
// CHECK-DAG: STW

// Unsigned loads (V850E1+)
// CHECK-DAG: LDBU
// CHECK-DAG: LDHU

