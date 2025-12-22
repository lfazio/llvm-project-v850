// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// SST.H - Short store halfword (Format IV)
// Syntax: sst.h reg2, disp8[ep]
// Operation: store.halfword(disp8 + EP) <- reg2[15:0]
// Uses EP (r30) as implicit base register

// CHECK: sst.h r5, 0[ep] ; encoding: [0x80,0x2c]
sst.h r5, 0

// CHECK: sst.h r10, 50[ep] ; encoding: [0xb2,0x54]
sst.h r10, 50

// CHECK: sst.h r31, 126[ep] ; encoding: [0xfe,0xfc]
sst.h r31, 126
