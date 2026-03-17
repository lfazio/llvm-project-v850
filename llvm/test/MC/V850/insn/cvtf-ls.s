// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CVTF.LS - Convert long (int64) to single

// CHECK: cvtf.ls d6, r7 ; encoding: [0xe1,0x37,0x42,0x3c]
cvtf.ls d6, r7

// CHECK: cvtf.ls d10, r15 ; encoding: [0xe1,0x57,0x42,0x7c]
cvtf.ls d10, r15

