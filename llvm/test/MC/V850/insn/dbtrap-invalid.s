// RUN: not llvm-mc -triple=v850 %s 2>&1 | FileCheck %s

// Test that V850E1 instructions are rejected on base V850

// CHECK: error: instruction requires a CPU feature not available
dbtrap
