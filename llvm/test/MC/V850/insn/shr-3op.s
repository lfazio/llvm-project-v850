// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// SHR - 3-operand shift right logical (Format XI, 32-bit)
// Syntax: shr reg1, reg2, reg3
// Operation: reg3 <- reg2 >> reg1 (logical)
// Requires: V850E2 or later

// CHECK: shr r5, r10, r20 ; encoding:
shr r5, r10, r20

// CHECK: shr r1, r6, r15 ; encoding:
shr r1, r6, r15

// CHECK: shr r10, r20, r25 ; encoding:
shr r10, r20, r25
