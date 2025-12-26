// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// SXH - Sign extend halfword (Format I variant, reg2=0)
// Syntax: sxh reg1
// Operation: reg1 <- sign_extend(reg1[15:0])

// CHECK: sxh r6 ; encoding: [0xe6,0x00]
sxh r6

// CHECK: sxh r10 ; encoding: [0xea,0x00]
sxh r10

// CHECK: sxh r20 ; encoding: [0xf4,0x00]
sxh r20

// CHECK: sxh r31 ; encoding: [0xff,0x00]
sxh r31
