// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CVTF.DW - Convert double to word (int32)

// CHECK: cvtf.dw r6, r8 ; encoding: [0xe4,0x37,0x50,0x44]
cvtf.dw r6, r8

// CHECK: cvtf.dw r10, r12 ; encoding: [0xe4,0x57,0x50,0x64]
cvtf.dw r10, r12

