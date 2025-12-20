// RUN: llvm-tblgen --gen-instr-info -I %p/../../../lib/Target/V850 \
// RUN:     -I %p/../../../include %p/../../../lib/Target/V850/V850.td \
// RUN:     | FileCheck %s

// Test Format VIII (Bit Manipulation) instruction definitions
// CHECK-DAG: SET1
// CHECK-DAG: NOT1
// CHECK-DAG: CLR1
// CHECK-DAG: TST1

// Test Format IX (Extended Register) instruction definitions
// CHECK-DAG: SETF
// CHECK-DAG: LDSR
// CHECK-DAG: STSR
// CHECK-DAG: SHL
// CHECK-DAG: SHR
// CHECK-DAG: SAR

// Test Format X (Special) instruction definitions
// CHECK-DAG: TRAP
// CHECK-DAG: HALT
// CHECK-DAG: RETI
// CHECK-DAG: DI
// CHECK-DAG: EI

