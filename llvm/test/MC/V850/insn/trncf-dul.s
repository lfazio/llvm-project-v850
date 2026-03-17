// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// TRNCF.DUL - Truncate double to unsigned long (uint64)

// CHECK: trncf.dul r6, d8 ; encoding: [0xf1,0x37,0x54,0x44]
trncf.dul r6, d8

// CHECK: trncf.dul r10, d12 ; encoding: [0xf1,0x57,0x54,0x64]
trncf.dul r10, d12

