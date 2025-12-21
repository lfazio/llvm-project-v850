// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// TST1 - Test bit in memory (Format VIII)
// Syntax: tst1 bit#3, disp16[reg1]
// Operation: Z flag <- ~(disp16 + reg1).bit

// CHECK: tst1 0, 0[r8] ; encoding: [0xc8,0xc7,0x00,0x00]
tst1 0, 0[r8]

// CHECK: tst1 5, 200[r15] ; encoding: [0xcf,0xef,0xc8,0x00]
tst1 5, 200[r15]
