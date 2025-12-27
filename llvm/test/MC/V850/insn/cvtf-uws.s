// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CVTF.UWS - Convert unsigned word (uint32) to single

// CHECK: cvtf.uws r6, r7 ; encoding: [0xf0,0x37,0x42,0x3c]
cvtf.uws r6, r7

// CHECK: cvtf.uws r10, r12 ; encoding: [0xf0,0x57,0x42,0x64]
cvtf.uws r10, r12

