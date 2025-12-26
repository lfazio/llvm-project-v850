// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// SXB - Sign extend byte (Format I variant, reg2=0)
// Syntax: sxb reg1
// Operation: reg1 <- sign_extend(reg1[7:0])

// CHECK: sxb r6 ; encoding: [0xa6,0x00]
sxb r6

// CHECK: sxb r10 ; encoding: [0xaa,0x00]
sxb r10

// CHECK: sxb r20 ; encoding: [0xb4,0x00]
sxb r20

// CHECK: sxb r31 ; encoding: [0xbf,0x00]
sxb r31
