// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// MACU - Multiply-accumulate unsigned (Format XI, 32-bit)
// Syntax: macu reg1, reg2, reg3, reg4
// Operation: (reg3:reg4) <- (reg3:reg4) + (reg1 * reg2) (unsigned)
// Requires: V850E2 or later

// CHECK: macu r5, r10, r20, r22 ; encoding: [0xe5,0x57,0xe0,0xa3]
macu r5, r10, r20, r22

// CHECK: macu r6, r12, r24, r26 ; encoding: [0xe6,0x67,0xe0,0xc3]
macu r6, r12, r24, r26

// CHECK: macu r8, r16, r20, r21 ; encoding: [0xe8,0x87,0xe0,0xa3]
macu r8, r16, r20, r21
