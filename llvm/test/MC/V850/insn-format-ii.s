// RUN: llvm-tblgen --gen-instr-info -I %p/../../../lib/Target/V850 \
// RUN:     -I %p/../../../include %p/../../../lib/Target/V850/V850.td \
// RUN:     | FileCheck %s

// Test Format II (5-bit Immediate-Register, 16-bit) instruction definitions

// CHECK-DAG: MOVi
// CHECK-DAG: SATADDi
// CHECK-DAG: ADDi
// CHECK-DAG: CMPi
// CHECK-DAG: SHRi
// CHECK-DAG: SARi
// CHECK-DAG: SHLi

