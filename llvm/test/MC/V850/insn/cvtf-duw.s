// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CVTF.DUW - Convert double to unsigned word (uint32)

// CHECK: cvtf.duw r6, r8 ; encoding: [0xf4,0x37,0x50,0x44]
cvtf.duw r6, r8

// CHECK: cvtf.duw r10, r12 ; encoding: [0xf4,0x57,0x50,0x64]
cvtf.duw r10, r12

