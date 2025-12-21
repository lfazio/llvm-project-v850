// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// SET1 - Set bit in memory (Format VIII)
// Syntax: set1 bit#3, disp16[reg1]
// Operation: (disp16 + reg1).bit <- 1

// CHECK: set1 0, 0[r10] ; encoding: [0xca,0x07,0x00,0x00]
set1 0, 0[r10]

// CHECK: set1 3, 100[r5] ; encoding: [0xc5,0x1f,0x64,0x00]
set1 3, 100[r5]

// CHECK: set1 7, -1[r20] ; encoding: [0xd4,0x3f,0xff,0xff]
set1 7, -1[r20]
