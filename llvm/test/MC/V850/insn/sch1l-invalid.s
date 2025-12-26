// RUN: not llvm-mc -triple=v850 %s 2>&1 | FileCheck %s
// RUN: not llvm-mc -triple=v850 -mcpu=v850e1 %s 2>&1 | FileCheck %s

// Test that V850E2 instructions are rejected on V850 and V850E1

// CHECK: error: instruction requires a CPU feature not available
sch1l r10, r20
