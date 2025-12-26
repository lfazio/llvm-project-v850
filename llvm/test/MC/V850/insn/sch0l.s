// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// SCH0L - Search zero from left (Format XI, 32-bit)
// Syntax: sch0l reg2, reg3
// Operation: reg3 <- position of first 0 bit from MSB (count leading ones)
// Requires: V850E2 or later

// CHECK: sch0l r10, r20 ; encoding: [0xe0,0x57,0x4c,0xa3]
sch0l r10, r20

// CHECK: sch0l r5, r15 ; encoding: [0xe0,0x2f,0x4c,0x7b]
sch0l r5, r15

// CHECK: sch0l r8, r18 ; encoding: [0xe0,0x47,0x4c,0x93]
sch0l r8, r18
