// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// TRNCF.DL - Truncate double to long (int64)

// CHECK: trncf.dl r6, d8 ; encoding: [0xe1,0x37,0x54,0x44]
trncf.dl r6, d8

// CHECK: trncf.dl r10, d12 ; encoding: [0xe1,0x57,0x54,0x64]
trncf.dl r10, d12

