// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// MUL - Multiply word (Format XI, 32-bit)
// Syntax: mul reg1, reg2, reg3
// Operation: reg2:reg3 <- reg2 * reg1 (signed 32x32 -> 64)

// CHECK: mul r5, r10, r20 ; encoding: [0xe5,0x57,0x22,0xa2]
mul r5, r10, r20

// CHECK: mul r6, r12, r22 ; encoding: [0xe6,0x67,0x22,0xb2]
mul r6, r12, r22

// CHECK: mul r7, r14, r24 ; encoding: [0xe7,0x77,0x22,0xc2]
mul r7, r14, r24
