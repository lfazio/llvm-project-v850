// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CVTF.SL - Convert single to long (int64)

// CHECK: cvtf.sl r7, d6 ; encoding: [0xe4,0x3f,0x44,0x34]
cvtf.sl r7, d6

// CHECK: cvtf.sl r10, d12 ; encoding: [0xe4,0x57,0x44,0x64]
cvtf.sl r10, d12

