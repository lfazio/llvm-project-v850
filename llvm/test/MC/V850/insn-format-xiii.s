// RUN: llvm-tblgen --gen-instr-info -I %p/../../../lib/Target/V850 \
// RUN:     -I %p/../../../include %p/../../../lib/Target/V850/V850.td \
// RUN:     | FileCheck %s

// Test Format XIII (PREPARE/DISPOSE, 32-bit) instruction definitions
// These are function prologue/epilogue helper instructions (V850E1+)

// CHECK-DAG: PREPARE
// CHECK-DAG: DISPOSE
// CHECK-DAG: DISPOSEr

