// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CVTF.SUW - Convert single to unsigned word (uint32)

// CHECK: cvtf.suw r7, r8 ; encoding: [0xf4,0x3f,0x40,0x44]
cvtf.suw r7, r8

// CHECK: cvtf.suw r10, r12 ; encoding: [0xf4,0x57,0x40,0x64]
cvtf.suw r10, r12

