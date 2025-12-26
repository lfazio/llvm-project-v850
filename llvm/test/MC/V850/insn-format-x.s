// RUN: llvm-tblgen --gen-instr-info -I %p/../../../lib/Target/V850 \
// RUN:     -I %p/../../../include %p/../../../lib/Target/V850/V850.td \
// RUN:     | FileCheck %s

// Test Format X (Extended 2, 32-bit) instruction definitions
// These are system/control instructions with extended opcode

// Trap and system control
// CHECK-DAG: TRAP
// CHECK-DAG: HALT
// CHECK-DAG: RETI
// CHECK-DAG: DI
// CHECK-DAG: EI

// CALLT return (V850E1+)
// CHECK-DAG: CTRET

// Debug return (V850E2+)
// CHECK-DAG: DBRET

