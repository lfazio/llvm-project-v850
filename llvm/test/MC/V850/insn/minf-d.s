// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// MINF.D - Double-precision floating-point minimum
// CHECK: minf.d r6, r8, r10 ; encoding: [0xe6,0x47,0x7a,0x54]
minf.d r6, r8, r10
