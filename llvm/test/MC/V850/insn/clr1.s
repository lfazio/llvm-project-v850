// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// CLR1 - Clear bit in memory (Format VIII)
// Syntax: clr1 bit#3, disp16[reg1]
// Operation: (disp16 + reg1).bit <- 0

// CHECK: clr1 0, 0[r10] ; encoding: [0xca,0x87,0x00,0x00]
clr1 0, 0[r10]

// CHECK: clr1 1, 25[r7] ; encoding: [0xc7,0x8f,0x19,0x00]
clr1 1, 25[r7]
