// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CVTF.ULD - Convert unsigned long (uint64) to double

// CHECK: cvtf.uld d6, r8 ; encoding: [0xf1,0x37,0x52,0x44]
cvtf.uld d6, r8

// CHECK: cvtf.uld d10, r12 ; encoding: [0xf1,0x57,0x52,0x64]
cvtf.uld d10, r12

