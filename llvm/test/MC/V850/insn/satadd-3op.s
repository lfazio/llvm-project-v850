// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// SATADD - 3-operand saturating add (Format XI, 32-bit)
// Syntax: satadd reg1, reg2, reg3
// Operation: reg3 <- saturate(reg2 + reg1)
// Requires: V850E2 or later

// CHECK: satadd r5, r10, r20 ; encoding:
satadd r5, r10, r20

// CHECK: satadd r1, r6, r15 ; encoding:
satadd r1, r6, r15

// CHECK: satadd r10, r20, r25 ; encoding:
satadd r10, r20, r25
