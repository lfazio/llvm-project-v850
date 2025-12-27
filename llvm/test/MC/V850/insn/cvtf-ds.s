// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CVTF.DS - Convert double to single
// Syntax: cvtf.ds reg2, reg3
// reg2 must be even (double-precision input)
// reg3 can be any GPR (single-precision output)

// CHECK: cvtf.ds r6, r7 ; encoding: [0xe3,0x37,0x52,0x3c]
cvtf.ds r6, r7

// CHECK: cvtf.ds r8, r10 ; encoding: [0xe3,0x47,0x52,0x54]
cvtf.ds r8, r10

// CHECK: cvtf.ds r10, r15 ; encoding: [0xe3,0x57,0x52,0x7c]
cvtf.ds r10, r15

