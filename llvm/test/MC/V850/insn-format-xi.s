// RUN: llvm-tblgen --gen-instr-info -I %p/../../../lib/Target/V850 \
// RUN:     -I %p/../../../include %p/../../../lib/Target/V850/V850.td \
// RUN:     | FileCheck %s

// Test Format XI (32-bit 3-operand extended) instruction definitions
// These instructions use the extended opcode 111111 with sub-opcodes

// Multiply instructions (Format XI)
// CHECK-DAG: MUL
// CHECK-DAG: MULU

// Divide instructions (Format XI)
// CHECK-DAG: DIV
// CHECK-DAG: DIVU
// CHECK-DAG: DIVHU
// CHECK-DAG: DIVH_3

// Conditional move (Format XI_Cond)
// CHECK-DAG: CMOVr

// V850E2 conditional arithmetic (Format XI_Cond)
// CHECK-DAG: ADF
// CHECK-DAG: SBF

// V850E2 multiply-accumulate (Format XI_Sub)
// CHECK-DAG: MAC
// CHECK-DAG: MACU

// V850E2 bit search (Format XI_2Op)
// CHECK-DAG: SCH0L
// CHECK-DAG: SCH0R
// CHECK-DAG: SCH1L
// CHECK-DAG: SCH1R

// Multiply with 9-bit immediate (Format XI_IMM9, V850E1+)
// CHECK-DAG: MULi
// CHECK-DAG: MULUi

// V850E2 3-operand shifts (Format XI)
// CHECK-DAG: SHR_3
// CHECK-DAG: SAR_3
// CHECK-DAG: SHL_3

// V850E2 3-operand saturated arithmetic (Format XI)
// CHECK-DAG: SATADD_3
// CHECK-DAG: SATSUB_3
