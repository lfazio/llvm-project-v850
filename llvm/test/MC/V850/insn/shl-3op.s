// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// SHL - 3-operand shift left logical (Format XI, 32-bit)
// Syntax: shl reg1, reg2, reg3
// Operation: reg3 <- reg2 << reg1
// Requires: V850E2 or later

// CHECK: shl r5, r10, r20 ; encoding:
shl r5, r10, r20

// CHECK: shl r1, r6, r15 ; encoding:
shl r1, r6, r15

// CHECK: shl r10, r20, r25 ; encoding:
shl r10, r20, r25
