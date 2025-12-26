// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// DIVU - Divide word unsigned (Format XI, 32-bit)
// Syntax: divu reg1, reg2, reg3
// Operation: reg2 <- reg2 / reg1, reg3 <- reg2 % reg1 (unsigned)

// CHECK: divu r5, r10, r20 ; encoding: [0xe5,0x57,0xc2,0xa2]
divu r5, r10, r20

// CHECK: divu r6, r12, r22 ; encoding: [0xe6,0x67,0xc2,0xb2]
divu r6, r12, r22

// CHECK: divu r8, r16, r26 ; encoding: [0xe8,0x87,0xc2,0xd2]
divu r8, r16, r26
