// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CVTF.UWD - Convert unsigned word (uint32) to double

// CHECK: cvtf.uwd r6, r8 ; encoding: [0xf0,0x37,0x52,0x44]
cvtf.uwd r6, r8

// CHECK: cvtf.uwd r10, r12 ; encoding: [0xf0,0x57,0x52,0x64]
cvtf.uwd r10, r12

