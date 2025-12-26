// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// MAC - Multiply-accumulate signed (Format XI, 32-bit)
// Syntax: mac reg1, reg2, reg3, reg4
// Operation: (reg3:reg4) <- (reg3:reg4) + (reg1 * reg2)
// Requires: V850E2 or later

// CHECK: mac r5, r10, r20, r22 ; encoding: [0xe5,0x57,0xc0,0xa3]
mac r5, r10, r20, r22

// CHECK: mac r6, r12, r24, r26 ; encoding: [0xe6,0x67,0xc0,0xc3]
mac r6, r12, r24, r26

// CHECK: mac r7, r14, r20, r21 ; encoding: [0xe7,0x77,0xc0,0xa3]
mac r7, r14, r20, r21
