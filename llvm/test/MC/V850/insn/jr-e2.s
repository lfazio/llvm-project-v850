// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// JR32 - Jump relative with 32-bit displacement (Format VI-E2, 48-bit)
// The 48-bit form is used when displacement exceeds 22-bit signed range.
// Syntax: jr disp32
// Operation: PC <- PC + sign_extend(disp32)
// Requires: V850E2 or later
//
// Values outside the 22-bit signed range [-2097152, 2097150] require JR32.

// CHECK: jr 2097152 ; encoding: [0xe0,0x02,0x00,0x00,0x10,0x00]
jr 2097152

// CHECK: jr -2097154 ; encoding: [0xe0,0x02,0xff,0xff,0xef,0xff]
jr -2097154

// CHECK: jr 16777216 ; encoding: [0xe0,0x02,0x00,0x00,0x80,0x00]
jr 16777216

// CHECK: jr -16777216 ; encoding: [0xe0,0x02,0x00,0x00,0x80,0xff]
jr -16777216
