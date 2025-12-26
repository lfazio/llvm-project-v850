// RUN: llvm-tblgen --gen-instr-info -I %p/../../../lib/Target/V850 \
// RUN:     -I %p/../../../include %p/../../../lib/Target/V850/V850.td \
// RUN:     | FileCheck %s

// Test Format IX (Extended 1, 32-bit) instruction definitions
// These use the extended opcode (111111) with sub-operation codes

// Condition code set
// CHECK-DAG: SETF

// System register access
// CHECK-DAG: LDSR
// CHECK-DAG: STSR

// Variable shifts (register operand)
// CHECK-DAG: SHR{{$}}
// CHECK-DAG: SAR{{$}}
// CHECK-DAG: SHL{{$}}

// Shift and add (V850E1+)
// CHECK-DAG: SASF

// Bit manipulation register form (V850E1+)
// CHECK-DAG: SET1r
// CHECK-DAG: CLR1r
// CHECK-DAG: NOT1r
// CHECK-DAG: TST1r

