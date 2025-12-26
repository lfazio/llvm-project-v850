// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// SCH1L - Search one from left (Format XI, 32-bit)
// Syntax: sch1l reg2, reg3
// Operation: reg3 <- position of first 1 bit from MSB (count leading zeros)
// Requires: V850E2 or later

// CHECK: sch1l r10, r20 ; encoding: [0xe0,0x57,0x4e,0xa3]
sch1l r10, r20

// CHECK: sch1l r7, r17 ; encoding: [0xe0,0x3f,0x4e,0x8b]
sch1l r7, r17

// CHECK: sch1l r11, r21 ; encoding: [0xe0,0x5f,0x4e,0xab]
sch1l r11, r21
