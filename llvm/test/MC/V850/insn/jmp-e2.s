// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// JMP32 - Jump with 32-bit displacement (Format VI-E2, 48-bit)
// Syntax: jmp disp32[reg1]
// Operation: PC <- reg1 + sign_extend(disp32)
// Requires: V850E2 or later

// CHECK: jmp 100[r5] ; encoding: [0xe5,0x06,0x32,0x00,0x00,0x00]
jmp 100[r5]

// CHECK: jmp 1000[r10] ; encoding: [0xea,0x06,0xf4,0x01,0x00,0x00]
jmp 1000[r10]

// CHECK: jmp 65536[r31] ; encoding: [0xff,0x06,0x00,0x80,0x00,0x00]
jmp 65536[r31]

// CHECK: jmp -100[r1] ; encoding: [0xe1,0x06,0xce,0xff,0xff,0xff]
jmp -100[r1]
