// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// ADDF.S - Single-precision floating-point add
// CHECK: addf.s r6, r7, r10 ; encoding: [0xe6,0x3f,0x60,0x54]
addf.s r6, r7, r10
