// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// ABSF.S - Single-precision floating-point absolute value
// CHECK: absf.s r7, r10 ; encoding: [0xe0,0x3f,0x48,0x54]
absf.s r7, r10
