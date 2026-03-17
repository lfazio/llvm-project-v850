// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// TRNCF.SUL - Truncate single to unsigned long (uint64)

// CHECK: trncf.sul r7, d6 ; encoding: [0xf1,0x3f,0x44,0x34]
trncf.sul r7, d6

// CHECK: trncf.sul r10, d12 ; encoding: [0xf1,0x57,0x44,0x64]
trncf.sul r10, d12

