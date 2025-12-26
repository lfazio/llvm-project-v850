// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// CLR1 - Clear bit in memory, register form (Format IX)
// Syntax: clr1 reg2, [reg1]
// Operation: (reg1).bit[reg2[2:0]] <- 0
// Requires: V850E1 or later

// CHECK: clr1 r5, [r10] ; encoding: [0xea,0x2f,0xe4,0x00]
clr1 r5, [r10]

// CHECK: clr1 r7, [r20] ; encoding: [0xf4,0x3f,0xe4,0x00]
clr1 r7, [r20]

// CHECK: clr1 r0, [r1] ; encoding: [0xe1,0x07,0xe4,0x00]
clr1 r0, [r1]
