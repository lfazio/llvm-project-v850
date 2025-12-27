// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// RSQRTF.D - Double-precision reciprocal square root
// CHECK: rsqrtf.d r8, r10 ; encoding: [0xe2,0x47,0x5c,0x54]
rsqrtf.d r8, r10
