// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// HSW - Halfword swap word (Format XI, 32-bit)
// Syntax: hsw reg2, reg3
// Operation: reg3 <- halfword_swap(reg2)
// Swaps two halfwords: ABCD -> CDAB (rotate by 16)

// CHECK: hsw r6, r10 ; encoding: [0xe0,0x37,0x44,0x53]
hsw r6, r10

// CHECK: hsw r10, r20 ; encoding: [0xe0,0x57,0x44,0xa3]
hsw r10, r20

// CHECK: hsw r15, r25 ; encoding: [0xe0,0x7f,0x44,0xcb]
hsw r15, r25
