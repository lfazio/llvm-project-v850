// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// ADDF.D - Double-precision floating-point add
// CHECK: addf.d r6, r8, r10 ; encoding: [0xe6,0x47,0x70,0x54]
addf.d r6, r8, r10
