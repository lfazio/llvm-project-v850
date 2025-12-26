// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// LD.B - Load byte (sign-extended) (Format VII)
// Syntax: ld.b disp16[reg1], reg2
// Operation: reg2 <- sign-extend(load.byte(disp16 + reg1))

// CHECK: ld.b 0[r10], r5 ; encoding: [0x0a,0x2f,0x00,0x00]
ld.b 0[r10], r5

// CHECK: ld.b 100[r15], r20 ; encoding: [0x0f,0xa7,0x64,0x00]
ld.b 100[r15], r20

// CHECK: ld.b -1[r0], r31 ; encoding: [0x00,0xff,0xff,0xff]
ld.b -1[r0], r31
