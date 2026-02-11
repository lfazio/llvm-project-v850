// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// JARL32 - Jump and register link with 32-bit displacement (Format VI-E2, 48-bit)
// The 48-bit form is used when displacement exceeds 22-bit signed range.
// Syntax: jarl disp32, reg1
// Operation: reg1 <- PC + 6, PC <- PC + sign_extend(disp32)
// Requires: V850E2 or later
//
// Values outside the 22-bit signed range [-2097152, 2097150] require JARL32.

// CHECK: jarl 2097152, r10 ; encoding: [0xea,0x02,0x00,0x00,0x10,0x00]
jarl 2097152, r10

// CHECK: jarl -2097154, r5 ; encoding: [0xe5,0x02,0xff,0xff,0xef,0xff]
jarl -2097154, r5

// CHECK: jarl 16777216, r31 ; encoding: [0xff,0x02,0x00,0x00,0x80,0x00]
jarl 16777216, r31

// CHECK: jarl -16777216, r1 ; encoding: [0xe1,0x02,0x00,0x00,0x80,0xff]
jarl -16777216, r1
