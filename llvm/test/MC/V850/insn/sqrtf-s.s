// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// SQRTF.S - Single-precision floating-point square root
// CHECK: sqrtf.s r7, r10 ; encoding: [0xe0,0x3f,0x5c,0x54]
sqrtf.s r7, r10
