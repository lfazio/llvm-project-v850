// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// TRNCF.SW - Truncate single to word (int32)

// CHECK: trncf.sw r7, r8 ; encoding: [0xe1,0x3f,0x40,0x44]
trncf.sw r7, r8

// CHECK: trncf.sw r10, r12 ; encoding: [0xe1,0x57,0x40,0x64]
trncf.sw r10, r12

