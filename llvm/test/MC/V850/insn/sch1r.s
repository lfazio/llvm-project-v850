// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// SCH1R - Search one from right (Format XI, 32-bit)
// Syntax: sch1r reg2, reg3
// Operation: reg3 <- position of first 1 bit from LSB (count trailing zeros)
// Requires: V850E2 or later

// CHECK: sch1r r10, r20 ; encoding: [0xe0,0x57,0x4a,0xa3]
sch1r r10, r20

// CHECK: sch1r r8, r18 ; encoding: [0xe0,0x47,0x4a,0x93]
sch1r r8, r18

// CHECK: sch1r r12, r22 ; encoding: [0xe0,0x67,0x4a,0xb3]
sch1r r12, r22
