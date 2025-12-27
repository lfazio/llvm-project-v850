// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// MSUBF.S - Floating-point multiply-subtract: reg4 = (reg2 * reg1) - reg3
// CHECK: msubf.s r6, r7, r10, r12 ; encoding: [0xe6,0x3f,0xb8,0x52]
msubf.s r6, r7, r10, r12
