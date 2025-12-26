// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// MULU - Multiply word unsigned (Format XI, 32-bit)
// Syntax: mulu reg1, reg2, reg3
// Operation: reg2:reg3 <- reg2 * reg1 (unsigned 32x32 -> 64)

// CHECK: mulu r5, r10, r20 ; encoding: [0xe5,0x57,0x24,0xa2]
mulu r5, r10, r20

// CHECK: mulu r6, r12, r22 ; encoding: [0xe6,0x67,0x24,0xb2]
mulu r6, r12, r22

// CHECK: mulu r8, r16, r26 ; encoding: [0xe8,0x87,0x24,0xd2]
mulu r8, r16, r26
