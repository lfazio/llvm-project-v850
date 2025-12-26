// RUN: llvm-tblgen --gen-instr-info -I %p/../../../lib/Target/V850 \
// RUN:     -I %p/../../../include %p/../../../lib/Target/V850/V850.td \
// RUN:     | FileCheck %s

// Test Format IV (Short Load/Store with EP, 16-bit) instruction definitions
// These use EP (r30) as implicit base register with 7-bit displacement

// Short loads
// CHECK-DAG: SLDB
// CHECK-DAG: SLDH
// CHECK-DAG: SLDW

// Short stores
// CHECK-DAG: SSTB
// CHECK-DAG: SSTH
// CHECK-DAG: SSTW

