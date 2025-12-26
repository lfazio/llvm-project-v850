// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// SATSUB - 3-operand saturating subtract (Format XI, 32-bit)
// Syntax: satsub reg1, reg2, reg3
// Operation: reg3 <- saturate(reg2 - reg1)
// Requires: V850E2 or later

// CHECK: satsub r5, r10, r20 ; encoding:
satsub r5, r10, r20

// CHECK: satsub r1, r6, r15 ; encoding:
satsub r1, r6, r15

// CHECK: satsub r10, r20, r25 ; encoding:
satsub r10, r20, r25
