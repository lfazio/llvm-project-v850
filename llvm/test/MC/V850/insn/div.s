// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// DIV - Divide word (Format XI, 32-bit)
// Syntax: div reg1, reg2, reg3
// Operation: reg2 <- reg2 / reg1, reg3 <- reg2 % reg1 (signed)

// CHECK: div r5, r10, r20 ; encoding: [0xe5,0x57,0x82,0xa2]
div r5, r10, r20

// CHECK: div r6, r12, r22 ; encoding: [0xe6,0x67,0x82,0xb2]
div r6, r12, r22

// CHECK: div r7, r14, r24 ; encoding: [0xe7,0x77,0x82,0xc2]
div r7, r14, r24
