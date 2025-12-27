// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// MAXF.D - Double-precision floating-point maximum
// CHECK: maxf.d r6, r8, r10 ; encoding: [0xe6,0x47,0x78,0x54]
maxf.d r6, r8, r10
