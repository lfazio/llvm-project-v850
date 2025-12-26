// RUN: llvm-tblgen --gen-instr-info -I %p/../../../lib/Target/V850 \
// RUN:     -I %p/../../../include %p/../../../lib/Target/V850/V850.td \
// RUN:     | FileCheck %s

// Test Format I instructions with reg2=0 constraint (16-bit)
// These are single-register operations using Format I with reg2 fixed to 0

// Sign/Zero extension
// CHECK-DAG: SXB
// CHECK-DAG: SXH
// CHECK-DAG: ZXB
// CHECK-DAG: ZXH

// Table switch
// CHECK-DAG: SWITCH
