// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// SLD.W - Short load word (Format IV)
// Syntax: sld.w disp8[ep], reg2
// Operation: reg2 <- load.word(disp8 + EP)
// Uses EP (r30) as implicit base register

// CHECK: sld.w 0[ep], r5 ; encoding: [0x01,0x2d]
sld.w 0, r5

// CHECK: sld.w 50[ep], r10 ; encoding: [0x33,0x55]
sld.w 50, r10

// CHECK: sld.w 124[ep], r31 ; encoding: [0x7d,0xfd]
sld.w 124, r31
