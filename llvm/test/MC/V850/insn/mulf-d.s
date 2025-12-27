// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// MULF.D - Double-precision floating-point multiply
// CHECK: mulf.d r6, r8, r10 ; encoding: [0xe6,0x47,0x74,0x54]
mulf.d r6, r8, r10
