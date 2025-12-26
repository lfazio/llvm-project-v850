// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// SAR - 3-operand shift right arithmetic (Format XI, 32-bit)
// Syntax: sar reg1, reg2, reg3
// Operation: reg3 <- reg2 >> reg1 (arithmetic, sign-extending)
// Requires: V850E2 or later

// CHECK: sar r5, r10, r20 ; encoding:
sar r5, r10, r20

// CHECK: sar r1, r6, r15 ; encoding:
sar r1, r6, r15

// CHECK: sar r10, r20, r25 ; encoding:
sar r10, r20, r25
