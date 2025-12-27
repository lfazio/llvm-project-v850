// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// NEGF.D - Double-precision floating-point negate
// CHECK: negf.d r8, r10 ; encoding: [0xe1,0x47,0x50,0x54]
negf.d r8, r10
