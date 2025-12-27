// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// TRNCF.DW - Truncate double to word (int32)

// CHECK: trncf.dw r6, r8 ; encoding: [0xe1,0x37,0x50,0x44]
trncf.dw r6, r8

// CHECK: trncf.dw r10, r12 ; encoding: [0xe1,0x57,0x50,0x64]
trncf.dw r10, r12

