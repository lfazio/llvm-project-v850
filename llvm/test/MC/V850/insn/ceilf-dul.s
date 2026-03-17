// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CEILF.DUL - Ceiling double to unsigned long (uint64)

// CHECK: ceilf.dul r6, d8 ; encoding: [0xf2,0x37,0x54,0x44]
ceilf.dul r6, d8

// CHECK: ceilf.dul r10, d12 ; encoding: [0xf2,0x57,0x54,0x64]
ceilf.dul r10, d12

