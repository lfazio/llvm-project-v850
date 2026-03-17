// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// FLOORF.SUL - Floor single to unsigned long (uint64)

// CHECK: floorf.sul r7, d6 ; encoding: [0xf3,0x3f,0x44,0x34]
floorf.sul r7, d6

// CHECK: floorf.sul r10, d12 ; encoding: [0xf3,0x57,0x44,0x64]
floorf.sul r10, d12

