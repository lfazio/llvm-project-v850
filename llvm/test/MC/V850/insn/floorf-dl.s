// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// FLOORF.DL - Floor double to long (int64)

// CHECK: floorf.dl r6, d8 ; encoding: [0xe3,0x37,0x54,0x44]
floorf.dl r6, d8

// CHECK: floorf.dl r10, d12 ; encoding: [0xe3,0x57,0x54,0x64]
floorf.dl r10, d12

