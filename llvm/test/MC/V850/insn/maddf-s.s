// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// MADDF.S - Floating-point multiply-add: reg4 = (reg2 * reg1) + reg3
// CHECK: maddf.s r6, r7, r10, r12 ; encoding: [0xe6,0x3f,0x98,0x52]
maddf.s r6, r7, r10, r12
