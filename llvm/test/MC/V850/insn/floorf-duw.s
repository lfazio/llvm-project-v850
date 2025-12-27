// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// FLOORF.DUW - Floor double to unsigned word (uint32)

// CHECK: floorf.duw r6, r8 ; encoding: [0xf3,0x37,0x50,0x44]
floorf.duw r6, r8

// CHECK: floorf.duw r10, r12 ; encoding: [0xf3,0x57,0x50,0x64]
floorf.duw r10, r12

