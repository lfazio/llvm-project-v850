// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// FLOORF.SW - Floor single to word (int32)

// CHECK: floorf.sw r7, r8 ; encoding: [0xe3,0x3f,0x40,0x44]
floorf.sw r7, r8

// CHECK: floorf.sw r10, r12 ; encoding: [0xe3,0x57,0x40,0x64]
floorf.sw r10, r12

