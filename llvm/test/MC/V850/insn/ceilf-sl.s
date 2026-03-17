// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CEILF.SL - Ceiling single to long (int64)

// CHECK: ceilf.sl r7, d6 ; encoding: [0xe2,0x3f,0x44,0x34]
ceilf.sl r7, d6

// CHECK: ceilf.sl r10, d12 ; encoding: [0xe2,0x57,0x44,0x64]
ceilf.sl r10, d12

