// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// BSH - Byte swap halfword (Format XI, 32-bit)
// Syntax: bsh reg2, reg3
// Operation: reg3 <- byte_swap_halfwords(reg2)
// Swaps bytes within each halfword: ABCD -> BADC

// CHECK: bsh r6, r10 ; encoding: [0xe0,0x37,0x42,0x53]
bsh r6, r10

// CHECK: bsh r10, r20 ; encoding: [0xe0,0x57,0x42,0xa3]
bsh r10, r20

// CHECK: bsh r15, r25 ; encoding: [0xe0,0x7f,0x42,0xcb]
bsh r15, r25
