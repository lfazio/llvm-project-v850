// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// JR32 - Jump relative with 32-bit displacement (Format VI-E2, 48-bit)
// Syntax: jr32 disp32
// Operation: PC <- PC + sign_extend(disp32)
// Requires: V850E2 or later

// CHECK: jr32 100 ; encoding: [0xe0,0x02,0x32,0x00,0x00,0x00]
jr32 100

// CHECK: jr32 1000 ; encoding: [0xe0,0x02,0xf4,0x01,0x00,0x00]
jr32 1000

// CHECK: jr32 65536 ; encoding: [0xe0,0x02,0x00,0x80,0x00,0x00]
jr32 65536

// CHECK: jr32 -100 ; encoding: [0xe0,0x02,0xce,0xff,0xff,0xff]
jr32 -100
