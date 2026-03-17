// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CEILF.DL - Ceiling double to long (int64)

// CHECK: ceilf.dl r6, d8 ; encoding: [0xe2,0x37,0x54,0x44]
ceilf.dl r6, d8

// CHECK: ceilf.dl r10, d12 ; encoding: [0xe2,0x57,0x54,0x64]
ceilf.dl r10, d12

