// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// JR - Jump relative with 32-bit displacement (Format VI-E2, 48-bit)
// On V850E2, "jr" uses the 48-bit form with 32-bit displacement
// Syntax: jr disp32
// Operation: PC <- PC + sign_extend(disp32)
// Requires: V850E2 or later

// CHECK: jr 100 ; encoding: [0xe0,0x02,0x32,0x00,0x00,0x00]
jr 100

// CHECK: jr 1000 ; encoding: [0xe0,0x02,0xf4,0x01,0x00,0x00]
jr 1000

// CHECK: jr 65536 ; encoding: [0xe0,0x02,0x00,0x80,0x00,0x00]
jr 65536

// CHECK: jr -100 ; encoding: [0xe0,0x02,0xce,0xff,0xff,0xff]
jr -100
