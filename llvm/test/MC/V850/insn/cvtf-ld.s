// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CVTF.LD - Convert long (int64) to double

// CHECK: cvtf.ld d6, r8 ; encoding: [0xe1,0x37,0x52,0x44]
cvtf.ld d6, r8

// CHECK: cvtf.ld d10, r12 ; encoding: [0xe1,0x57,0x52,0x64]
cvtf.ld d10, r12

