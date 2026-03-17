// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CVTF.ULS - Convert unsigned long (uint64) to single

// CHECK: cvtf.uls d6, r7 ; encoding: [0xf1,0x37,0x42,0x3c]
cvtf.uls d6, r7

// CHECK: cvtf.uls d10, r15 ; encoding: [0xf1,0x57,0x42,0x7c]
cvtf.uls d10, r15

