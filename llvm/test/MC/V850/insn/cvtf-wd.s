// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CVTF.WD - Convert word (int32) to double

// CHECK: cvtf.wd r6, r8 ; encoding: [0xe0,0x37,0x52,0x44]
cvtf.wd r6, r8

// CHECK: cvtf.wd r10, r12 ; encoding: [0xe0,0x57,0x52,0x64]
cvtf.wd r10, r12

