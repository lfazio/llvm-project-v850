// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// RSQRTF.S - Single-precision reciprocal square root
// CHECK: rsqrtf.s r7, r10 ; encoding: [0xe2,0x3f,0x5c,0x54]
rsqrtf.s r7, r10
