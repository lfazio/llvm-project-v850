// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CAXI - Compare And Exchange for Interlock (Format XI, 32-bit)
// Syntax: caxi [reg1], reg2, reg3
// Operation: old = *[reg1]; if (old == reg2) *[reg1] = reg3; reg3 = old

// CHECK: caxi [r6], r7, r8 ; encoding: [0xe6,0x3f,0xee,0x40]
caxi [r6], r7, r8

// CHECK: caxi [r10], r11, r12 ; encoding: [0xea,0x5f,0xee,0x60]
caxi [r10], r11, r12

// CHECK: caxi [r20], r21, r22 ; encoding: [0xf4,0xaf,0xee,0xb0]
caxi [r20], r21, r22

// CHECK: caxi [r1], r2, r3 ; encoding: [0xe1,0x17,0xee,0x18]
caxi [r1], r2, r3

// CHECK: caxi [r31], r30, r29 ; encoding: [0xff,0xf7,0xee,0xe8]
caxi [r31], r30, r29
