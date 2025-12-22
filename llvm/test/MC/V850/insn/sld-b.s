// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// SLD.B - Short load byte (Format IV)
// Syntax: sld.b disp7[ep], reg2
// Operation: reg2 <- sign-extend(load.byte(disp7 + EP))
// Uses EP (r30) as implicit base register

// CHECK: sld.b 0[ep], r5 ; encoding: [0x00,0x2b]
sld.b 0, r5

// CHECK: sld.b 50[ep], r10 ; encoding: [0x32,0x53]
sld.b 50, r10

// CHECK: sld.b 127[ep], r31 ; encoding: [0x7f,0xfb]
sld.b 127, r31
