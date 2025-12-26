// RUN: llvm-tblgen --gen-instr-info -I %p/../../../lib/Target/V850 \
// RUN:     -I %p/../../../include %p/../../../lib/Target/V850/V850.td \
// RUN:     | FileCheck %s

// Test CALLT format (16-bit table call) instruction definitions

// CALLT - Call with table look up
// CHECK-DAG: CALLT

// CTRET - Return from CALLT (uses Format X)
// CHECK-DAG: CTRET
