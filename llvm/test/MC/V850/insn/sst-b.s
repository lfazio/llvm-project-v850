// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// SST.B - Short store byte (Format IV)
// Syntax: sst.b reg2, disp7[ep]
// Operation: store.byte(disp7 + EP) <- reg2[7:0]
// Uses EP (r30) as implicit base register

// CHECK: sst.b r5, 0[ep] ; encoding: [0x80,0x2b]
sst.b r5, 0

// CHECK: sst.b r10, 50[ep] ; encoding: [0xb2,0x53]
sst.b r10, 50

// CHECK: sst.b r31, 127[ep] ; encoding: [0xff,0xfb]
sst.b r31, 127
