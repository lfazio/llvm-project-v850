// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// HSH - Halfword swap halfword (Format XII, 32-bit)
// Syntax: hsh reg2, reg3
// Operation: reg3 <- swap bytes in each halfword of reg2
// AABBCCDD -> BBAADDCC (swap bytes within each 16-bit halfword)
// Requires: V850E2 or later

// CHECK: hsh r10, r20 ; encoding: [0xe0,0x57,0x46,0xa3]
hsh r10, r20

// CHECK: hsh r7, r17 ; encoding: [0xe0,0x3f,0x46,0x8b]
hsh r7, r17

// CHECK: hsh r11, r21 ; encoding: [0xe0,0x5f,0x46,0xab]
hsh r11, r21
