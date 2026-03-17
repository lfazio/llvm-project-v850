// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CVTF.DL - Convert double to long (int64)

// CHECK: cvtf.dl r6, d8 ; encoding: [0xe4,0x37,0x54,0x44]
cvtf.dl r6, d8

// CHECK: cvtf.dl r10, d12 ; encoding: [0xe4,0x57,0x54,0x64]
cvtf.dl r10, d12

