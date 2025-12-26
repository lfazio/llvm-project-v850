// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// ADF - Add on condition flag (Format XI, 32-bit)
// Syntax: adf cond, reg1, reg2, reg3
// Operation: if (cond) reg3 <- reg2 + reg1 + CY else reg3 <- reg2 + CY
// Requires: V850E2 or later

// CHECK: adf v, r5, r10, r20 ; encoding: [0xe5,0x57,0xa0,0xa3]
adf v, r5, r10, r20

// CHECK: adf c, r6, r11, r21 ; encoding: [0xe6,0x5f,0xa2,0xab]
adf c, r6, r11, r21

// CHECK: adf z, r7, r12, r22 ; encoding: [0xe7,0x67,0xa4,0xb3]
adf z, r7, r12, r22

// CHECK: adf nz, r8, r13, r23 ; encoding: [0xe8,0x6f,0xb4,0xbb]
adf nz, r8, r13, r23

// CHECK: adf lt, r5, r10, r20 ; encoding: [0xe5,0x57,0xac,0xa3]
adf lt, r5, r10, r20

// CHECK: adf ge, r6, r11, r21 ; encoding: [0xe6,0x5f,0xbc,0xab]
adf ge, r6, r11, r21
