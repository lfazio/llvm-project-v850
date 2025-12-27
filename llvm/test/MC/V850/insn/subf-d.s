// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// SUBF.D - Double-precision floating-point subtract
// CHECK: subf.d r6, r8, r10 ; encoding: [0xe6,0x47,0x72,0x54]
subf.d r6, r8, r10
