// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// FLOORF.DW - Floor double to word (int32)

// CHECK: floorf.dw r6, r8 ; encoding: [0xe3,0x37,0x50,0x44]
floorf.dw r6, r8

// CHECK: floorf.dw r10, r12 ; encoding: [0xe3,0x57,0x50,0x64]
floorf.dw r10, r12

