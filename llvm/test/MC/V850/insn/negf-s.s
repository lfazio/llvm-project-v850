// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// NEGF.S - Single-precision floating-point negate
// CHECK: negf.s r7, r10 ; encoding: [0xe0,0x3f,0x50,0x54]
negf.s r7, r10
