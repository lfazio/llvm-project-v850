// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// SQRTF.D - Double-precision floating-point square root
// CHECK: sqrtf.d r8, r10 ; encoding: [0xe0,0x47,0x5c,0x54]
sqrtf.d r8, r10
