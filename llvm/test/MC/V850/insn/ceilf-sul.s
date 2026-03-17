// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CEILF.SUL - Ceiling single to unsigned long (uint64)

// CHECK: ceilf.sul r7, d6 ; encoding: [0xf2,0x3f,0x44,0x34]
ceilf.sul r7, d6

// CHECK: ceilf.sul r10, d12 ; encoding: [0xf2,0x57,0x44,0x64]
ceilf.sul r10, d12

