// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CVTF.SD - Convert single to double

// CHECK: cvtf.sd r7, r6 ; encoding: [0xe2,0x3f,0x52,0x34]
cvtf.sd r7, r6

// CHECK: cvtf.sd r10, r8 ; encoding: [0xe2,0x57,0x52,0x44]
cvtf.sd r10, r8

