// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// DIVF.D - Double-precision floating-point divide
// CHECK: divf.d r6, r8, r10 ; encoding: [0xe6,0x47,0x7e,0x54]
divf.d r6, r8, r10
