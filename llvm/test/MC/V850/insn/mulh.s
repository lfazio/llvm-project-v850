// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// MULH - Multiply halfword (Format I)
// Syntax: mulh reg1, reg2
// Operation: reg2 <- (reg2[15:0] * reg1[15:0]) (signed)

// CHECK: mulh r1, r2 ; encoding: [0xe1,0x10]
mulh r1, r2

// CHECK: mulh r5, r10 ; encoding: [0xe5,0x50]
mulh r5, r10

// CHECK: mulh r31, r31 ; encoding: [0xff,0xf8]
mulh r31, r31
