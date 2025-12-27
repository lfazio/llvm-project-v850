// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// NMADDF.S - Floating-point negate multiply-add: reg4 = -((reg2 * reg1) + reg3)
// CHECK: nmaddf.s r6, r7, r10, r12 ; encoding: [0xe6,0x3f,0xd8,0x52]
nmaddf.s r6, r7, r10, r12
