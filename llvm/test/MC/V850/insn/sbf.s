// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// SBF - Subtract on condition flag (Format XI, 32-bit)
// Syntax: sbf cond, reg1, reg2, reg3
// Operation: if (cond) reg3 <- reg2 - reg1 - CY else reg3 <- reg2 - CY
// Requires: V850E2 or later

// CHECK: sbf v, r5, r10, r20 ; encoding: [0xe5,0x57,0x80,0xa3]
sbf v, r5, r10, r20

// CHECK: sbf c, r6, r11, r21 ; encoding: [0xe6,0x5f,0x82,0xab]
sbf c, r6, r11, r21

// CHECK: sbf z, r7, r12, r22 ; encoding: [0xe7,0x67,0x84,0xb3]
sbf z, r7, r12, r22

// CHECK: sbf nz, r8, r13, r23 ; encoding: [0xe8,0x6f,0x94,0xbb]
sbf nz, r8, r13, r23

// CHECK: sbf lt, r7, r14, r24 ; encoding: [0xe7,0x77,0x8c,0xc3]
sbf lt, r7, r14, r24

// CHECK: sbf ge, r8, r16, r26 ; encoding: [0xe8,0x87,0x9c,0xd3]
sbf ge, r8, r16, r26
