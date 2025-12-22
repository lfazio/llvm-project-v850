// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// LD.W - Load word (Format VII)
// Syntax: ld.w disp16[reg1], reg2
// Operation: reg2 <- load.word(disp16 + reg1)

// CHECK: ld.w 0[r10], r5 ; encoding: [0x2a,0x2f,0x01,0x00]
ld.w 0[r10], r5

// CHECK: ld.w 100[r15], r20 ; encoding: [0x2f,0xa7,0x65,0x00]
ld.w 100[r15], r20

// CHECK: ld.w -4[r0], r31 ; encoding: [0x20,0xff,0xfd,0xff]
ld.w -4[r0], r31
