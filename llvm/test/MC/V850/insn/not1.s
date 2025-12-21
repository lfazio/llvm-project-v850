// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// NOT1 - Toggle bit in memory (Format VIII)
// Syntax: not1 bit#3, disp16[reg1]
// Operation: (disp16 + reg1).bit <- ~(disp16 + reg1).bit

// CHECK: not1 0, 0[r10] ; encoding: [0xca,0x47,0x00,0x00]
not1 0, 0[r10]

// CHECK: not1 2, 50[r6] ; encoding: [0xc6,0x57,0x32,0x00]
not1 2, 50[r6]
