// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// FLOORF.SUW - Floor single to unsigned word (uint32)

// CHECK: floorf.suw r7, r8 ; encoding: [0xf3,0x3f,0x40,0x44]
floorf.suw r7, r8

// CHECK: floorf.suw r10, r12 ; encoding: [0xf3,0x57,0x40,0x64]
floorf.suw r10, r12

