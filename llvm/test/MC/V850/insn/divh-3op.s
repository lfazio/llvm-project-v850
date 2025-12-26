// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// DIVH - Divide halfword 3-operand form (Format XI, 32-bit)
// Syntax: divh reg1, reg2, reg3
// Operation: reg2 <- reg2 / reg1 (quotient), reg3 <- reg2 % reg1 (remainder)
// Requires: V850E1 or later

// CHECK: divh r5, r10, r15 ; encoding: [0xe5,0x57,0x80,0x7a]
divh r5, r10, r15

// CHECK: divh r1, r2, r3 ; encoding: [0xe1,0x17,0x80,0x1a]
divh r1, r2, r3

// CHECK: divh r10, r20, r25 ; encoding: [0xea,0xa7,0x80,0xca]
divh r10, r20, r25
