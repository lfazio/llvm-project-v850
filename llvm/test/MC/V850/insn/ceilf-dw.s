// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CEILF.DW - Ceiling double to word (int32)

// CHECK: ceilf.dw r6, r8 ; encoding: [0xe2,0x37,0x50,0x44]
ceilf.dw r6, r8

// CHECK: ceilf.dw r10, r12 ; encoding: [0xe2,0x57,0x50,0x64]
ceilf.dw r10, r12

