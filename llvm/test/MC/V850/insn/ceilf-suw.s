// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CEILF.SUW - Ceiling single to unsigned word (uint32)

// CHECK: ceilf.suw r7, r8 ; encoding: [0xf2,0x3f,0x40,0x44]
ceilf.suw r7, r8

// CHECK: ceilf.suw r10, r12 ; encoding: [0xf2,0x57,0x40,0x64]
ceilf.suw r10, r12

