// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// SET1 - Set bit in memory, register form (Format IX)
// Syntax: set1 reg2, [reg1]
// Operation: (reg1).bit[reg2[2:0]] <- 1
// Requires: V850E1 or later

// CHECK: set1 r5, [r10] ; encoding: [0xea,0x2f,0xe0,0x00]
set1 r5, [r10]

// CHECK: set1 r7, [r20] ; encoding: [0xf4,0x3f,0xe0,0x00]
set1 r7, [r20]

// CHECK: set1 r0, [r1] ; encoding: [0xe1,0x07,0xe0,0x00]
set1 r0, [r1]
