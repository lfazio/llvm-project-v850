// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// FLOORF.DUL - Floor double to unsigned long (uint64)

// CHECK: floorf.dul r6, d8 ; encoding: [0xf3,0x37,0x54,0x44]
floorf.dul r6, d8

// CHECK: floorf.dul r10, d12 ; encoding: [0xf3,0x57,0x54,0x64]
floorf.dul r10, d12

