// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CVTF.SW - Convert single to word (int32)

// CHECK: cvtf.sw r7, r8 ; encoding: [0xe4,0x3f,0x40,0x44]
cvtf.sw r7, r8

// CHECK: cvtf.sw r10, r12 ; encoding: [0xe4,0x57,0x40,0x64]
cvtf.sw r10, r12

