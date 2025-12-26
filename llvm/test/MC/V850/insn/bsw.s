// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// BSW - Byte swap word (Format XI, 32-bit)
// Syntax: bsw reg2, reg3
// Operation: reg3 <- byte_swap(reg2)
// Reverses all 4 bytes: ABCD -> DCBA

// CHECK: bsw r6, r10 ; encoding: [0xe0,0x37,0x40,0x53]
bsw r6, r10

// CHECK: bsw r10, r20 ; encoding: [0xe0,0x57,0x40,0xa3]
bsw r10, r20

// CHECK: bsw r15, r25 ; encoding: [0xe0,0x7f,0x40,0xcb]
bsw r15, r25
