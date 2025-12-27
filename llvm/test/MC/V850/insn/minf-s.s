// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// MINF.S - Single-precision floating-point minimum
// CHECK: minf.s r6, r7, r10 ; encoding: [0xe6,0x3f,0x6a,0x54]
minf.s r6, r7, r10
