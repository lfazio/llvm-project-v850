// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// SUBF.S - Single-precision floating-point subtract
// CHECK: subf.s r6, r7, r10 ; encoding: [0xe6,0x3f,0x62,0x54]
subf.s r6, r7, r10
