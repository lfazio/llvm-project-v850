// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CVTF.SUL - Convert single to unsigned long (uint64)

// CHECK: cvtf.sul r7, d6 ; encoding: [0xf4,0x3f,0x44,0x34]
cvtf.sul r7, d6

// CHECK: cvtf.sul r10, d12 ; encoding: [0xf4,0x57,0x44,0x64]
cvtf.sul r10, d12

