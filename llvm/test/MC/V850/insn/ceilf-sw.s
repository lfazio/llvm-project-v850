// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CEILF.SW - Ceiling single to word (int32)

// CHECK: ceilf.sw r7, r8 ; encoding: [0xe2,0x3f,0x40,0x44]
ceilf.sw r7, r8

// CHECK: ceilf.sw r10, r12 ; encoding: [0xe2,0x57,0x40,0x64]
ceilf.sw r10, r12

