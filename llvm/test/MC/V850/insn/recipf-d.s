// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// RECIPF.D - Double-precision floating-point reciprocal
// CHECK: recipf.d r8, r10 ; encoding: [0xe1,0x47,0x5c,0x54]
recipf.d r8, r10
