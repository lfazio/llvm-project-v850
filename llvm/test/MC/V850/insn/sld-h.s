// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// SLD.H - Short load halfword (Format IV)
// Syntax: sld.h disp8[ep], reg2
// Operation: reg2 <- sign-extend(load.halfword(disp8 + EP))
// Uses EP (r30) as implicit base register

// CHECK: sld.h 0[ep], r5 ; encoding: [0x00,0x2c]
sld.h 0, r5

// CHECK: sld.h 50[ep], r10 ; encoding: [0x32,0x54]
sld.h 50, r10

// CHECK: sld.h 126[ep], r31 ; encoding: [0x7e,0xfc]
sld.h 126, r31
