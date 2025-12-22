// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// LD.H - Load halfword (sign-extended) (Format VII)
// Syntax: ld.h disp16[reg1], reg2
// Operation: reg2 <- sign-extend(load.halfword(disp16 + reg1))

// CHECK: ld.h 0[r10], r5 ; encoding: [0x2a,0x2f,0x00,0x00]
ld.h 0[r10], r5

// CHECK: ld.h 100[r15], r20 ; encoding: [0x2f,0xa7,0x64,0x00]
ld.h 100[r15], r20

// CHECK: ld.h -2[r0], r31 ; encoding: [0x20,0xff,0xfe,0xff]
ld.h -2[r0], r31
