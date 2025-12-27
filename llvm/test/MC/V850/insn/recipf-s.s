// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// RECIPF.S - Single-precision floating-point reciprocal
// CHECK: recipf.s r7, r10 ; encoding: [0xe1,0x3f,0x5c,0x54]
recipf.s r7, r10
