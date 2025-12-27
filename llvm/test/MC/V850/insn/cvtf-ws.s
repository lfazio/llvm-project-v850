// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CVTF.WS - Convert word (int32) to single

// CHECK: cvtf.ws r6, r7 ; encoding: [0xe0,0x37,0x42,0x3c]
cvtf.ws r6, r7

// CHECK: cvtf.ws r10, r12 ; encoding: [0xe0,0x57,0x42,0x64]
cvtf.ws r10, r12

