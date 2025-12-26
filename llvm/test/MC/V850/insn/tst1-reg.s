// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// TST1 - Test bit in memory, register form (Format IX)
// Syntax: tst1 reg2, [reg1]
// Operation: Z flag <- ~(reg1).bit[reg2[2:0]]
// Requires: V850E1 or later

// CHECK: tst1 r5, [r10] ; encoding: [0xea,0x2f,0xe6,0x00]
tst1 r5, [r10]

// CHECK: tst1 r7, [r20] ; encoding: [0xf4,0x3f,0xe6,0x00]
tst1 r7, [r20]

// CHECK: tst1 r0, [r1] ; encoding: [0xe1,0x07,0xe6,0x00]
tst1 r0, [r1]
