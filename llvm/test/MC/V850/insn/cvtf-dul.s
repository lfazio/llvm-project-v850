// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CVTF.DUL - Convert double to unsigned long (uint64)

// CHECK: cvtf.dul r6, d8 ; encoding: [0xf4,0x37,0x54,0x44]
cvtf.dul r6, d8

// CHECK: cvtf.dul r10, d12 ; encoding: [0xf4,0x57,0x54,0x64]
cvtf.dul r10, d12

