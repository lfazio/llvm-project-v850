// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CVTF.DL - Convert double to long (int64)

// CHECK: cvtf.dl r6, r8 ; encoding: [0xe4,0x37,0x54,0x44]
cvtf.dl r6, r8

// CHECK: cvtf.dl r10, r12 ; encoding: [0xe4,0x57,0x54,0x64]
cvtf.dl r10, r12

