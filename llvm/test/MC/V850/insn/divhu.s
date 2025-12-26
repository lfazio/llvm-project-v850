// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// DIVHU - Divide halfword unsigned (Format XI, 32-bit)
// Syntax: divhu reg1, reg2, reg3
// Operation: reg2 <- reg2[15:0] / reg1[15:0], reg3 <- reg2[15:0] % reg1[15:0]

// CHECK: divhu r7, r14, r24 ; encoding: [0xe7,0x77,0xa2,0xc2]
divhu r7, r14, r24

// CHECK: divhu r9, r18, r28 ; encoding: [0xe9,0x97,0xa2,0xe2]
divhu r9, r18, r28
