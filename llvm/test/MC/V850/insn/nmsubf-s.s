// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// NMSUBF.S - Floating-point negate multiply-subtract: reg4 = -((reg2 * reg1) - reg3)
// CHECK: nmsubf.s r6, r7, r10, r12 ; encoding: [0xe6,0x3f,0xf8,0x52]
nmsubf.s r6, r7, r10, r12
