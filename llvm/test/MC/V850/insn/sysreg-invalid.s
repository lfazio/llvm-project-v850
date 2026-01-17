// RUN: not llvm-mc -triple=v850 %s 2>&1 | FileCheck %s --check-prefix=CHECK-BASE
// RUN: not llvm-mc -triple=v850 -mcpu=v850e1 %s 2>&1 | FileCheck %s --check-prefix=CHECK-E1

// Test that system registers are properly validated based on CPU features

// V850E1+ registers should fail on base V850
// CHECK-BASE: error: system register requires V850E1 or later CPU
stsr ctpc, r10

// CHECK-BASE: error: system register requires V850E1 or later CPU
ldsr r10, ctpsw

// CHECK-BASE: error: system register requires V850E1 or later CPU
stsr ctbp, r5

// V850E2M+ registers should fail on base V850 and V850E1
// CHECK-BASE: error: system register requires V850E2M or later CPU
// CHECK-E1: error: system register requires V850E2M or later CPU
stsr eiwr, r10

// CHECK-BASE: error: system register requires V850E2M or later CPU
// CHECK-E1: error: system register requires V850E2M or later CPU
ldsr r10, fewr

// CHECK-BASE: error: system register requires V850E2M or later CPU
// CHECK-E1: error: system register requires V850E2M or later CPU
stsr bsel, r5
