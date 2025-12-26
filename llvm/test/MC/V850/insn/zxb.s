// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// ZXB - Zero extend byte (Format I variant, reg2=0)
// Syntax: zxb reg1
// Operation: reg1 <- zero_extend(reg1[7:0])

// CHECK: zxb r6 ; encoding: [0x86,0x00]
zxb r6

// CHECK: zxb r10 ; encoding: [0x8a,0x00]
zxb r10

// CHECK: zxb r20 ; encoding: [0x94,0x00]
zxb r20

// CHECK: zxb r31 ; encoding: [0x9f,0x00]
zxb r31
