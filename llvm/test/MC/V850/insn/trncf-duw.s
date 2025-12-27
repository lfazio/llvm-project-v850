// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// TRNCF.DUW - Truncate double to unsigned word (uint32)

// CHECK: trncf.duw r6, r8 ; encoding: [0xf1,0x37,0x50,0x44]
trncf.duw r6, r8

// CHECK: trncf.duw r10, r12 ; encoding: [0xf1,0x57,0x50,0x64]
trncf.duw r10, r12

