// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// JARL32 - Jump and register link with 32-bit displacement (Format VI-E2, 48-bit)
// Syntax: jarl32 disp32, reg1
// Operation: reg1 <- PC + 6, PC <- PC + sign_extend(disp32)
// Requires: V850E2 or later

// CHECK: jarl32 100, r10 ; encoding: [0xea,0x02,0x32,0x00,0x00,0x00]
jarl32 100, r10

// CHECK: jarl32 1000, r5 ; encoding: [0xe5,0x02,0xf4,0x01,0x00,0x00]
jarl32 1000, r5

// CHECK: jarl32 65536, r31 ; encoding: [0xff,0x02,0x00,0x80,0x00,0x00]
jarl32 65536, r31

// CHECK: jarl32 -100, r1 ; encoding: [0xe1,0x02,0xce,0xff,0xff,0xff]
jarl32 -100, r1
