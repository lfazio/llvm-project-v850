// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CEILF.DUW - Ceiling double to unsigned word (uint32)

// CHECK: ceilf.duw r6, r8 ; encoding: [0xf2,0x37,0x50,0x44]
ceilf.duw r6, r8

// CHECK: ceilf.duw r10, r12 ; encoding: [0xf2,0x57,0x50,0x64]
ceilf.duw r10, r12

