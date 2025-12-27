// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// ABSF.D - Double-precision floating-point absolute value
// CHECK: absf.d r8, r10 ; encoding: [0xe0,0x47,0x58,0x54]
absf.d r8, r10
