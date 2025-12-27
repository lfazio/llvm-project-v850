// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// TRNCF.SUW - Truncate single to unsigned word (uint32)

// CHECK: trncf.suw r7, r8 ; encoding: [0xf1,0x3f,0x40,0x44]
trncf.suw r7, r8

// CHECK: trncf.suw r10, r12 ; encoding: [0xf1,0x57,0x40,0x64]
trncf.suw r10, r12

