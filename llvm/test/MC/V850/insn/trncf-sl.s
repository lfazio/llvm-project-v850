// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// TRNCF.SL - Truncate single to long (int64)

// CHECK: trncf.sl r7, d6 ; encoding: [0xe1,0x3f,0x44,0x34]
trncf.sl r7, d6

// CHECK: trncf.sl r10, d12 ; encoding: [0xe1,0x57,0x44,0x64]
trncf.sl r10, d12

