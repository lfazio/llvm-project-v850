// RUN: llvm-tblgen --gen-instr-info -I %p/../../../lib/Target/V850 \
// RUN:     -I %p/../../../include %p/../../../lib/Target/V850/V850.td \
// RUN:     | FileCheck %s

// Test Format XII (32-bit conditional with immediate) instruction definitions

// Conditional move with immediate (Format XII_Cond)
// CHECK-DAG: CMOVi
