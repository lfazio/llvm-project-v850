// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// SST.W - Short store word (Format IV)
// Syntax: sst.w reg2, disp8[ep]
// Operation: store.word(disp8 + EP) <- reg2
// Uses EP (r30) as implicit base register

// CHECK: sst.w r5, 0[ep] ; encoding: [0x00,0x2d]
sst.w r5, 0

// CHECK: sst.w r10, 50[ep] ; encoding: [0x32,0x55]
sst.w r10, 50

// CHECK: sst.w r31, 124[ep] ; encoding: [0x7c,0xfd]
sst.w r31, 124
