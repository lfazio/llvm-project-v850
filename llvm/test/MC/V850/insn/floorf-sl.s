// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// FLOORF.SL - Floor single to long (int64)

// CHECK: floorf.sl r7, r6 ; encoding: [0xe3,0x3f,0x44,0x34]
floorf.sl r7, r6

// CHECK: floorf.sl r10, r12 ; encoding: [0xe3,0x57,0x44,0x64]
floorf.sl r10, r12

