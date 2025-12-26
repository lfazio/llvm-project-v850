// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// ZXH - Zero extend halfword (Format I variant, reg2=0)
// Syntax: zxh reg1
// Operation: reg1 <- zero_extend(reg1[15:0])

// CHECK: zxh r6 ; encoding: [0xc6,0x00]
zxh r6

// CHECK: zxh r10 ; encoding: [0xca,0x00]
zxh r10

// CHECK: zxh r20 ; encoding: [0xd4,0x00]
zxh r20

// CHECK: zxh r31 ; encoding: [0xdf,0x00]
zxh r31
