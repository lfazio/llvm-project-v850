// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CMPF.S - Single-precision floating-point compare
// Syntax: cmpf.s fcond, reg1, reg2, fcbit
// Sets FPCC[fcbit] based on comparing reg2 to reg1 using condition fcond

// fcond 0 (F) - False
// CHECK: cmpf.s 0, r6, r7, 0 ; encoding: [0xe6,0x3f,0x30,0x04]
cmpf.s 0, r6, r7, 0

// fcond 2 (EQ) - Equal
// CHECK: cmpf.s 2, r6, r7, 0 ; encoding: [0xe6,0x3f,0x30,0x14]
cmpf.s 2, r6, r7, 0

// fcond 4 (OLT) - Ordered Less Than
// CHECK: cmpf.s 4, r10, r11, 1 ; encoding: [0xea,0x5f,0x32,0x24]
cmpf.s 4, r10, r11, 1

// fcond 6 (OLE) - Ordered Less or Equal
// CHECK: cmpf.s 6, r6, r7, 2 ; encoding: [0xe6,0x3f,0x34,0x34]
cmpf.s 6, r6, r7, 2

// fcond 12 (LT) - Less Than
// CHECK: cmpf.s 12, r6, r7, 3 ; encoding: [0xe6,0x3f,0x36,0x64]
cmpf.s 12, r6, r7, 3

// fcond 14 (LE) - Less or Equal
// CHECK: cmpf.s 14, r6, r7, 7 ; encoding: [0xe6,0x3f,0x3e,0x74]
cmpf.s 14, r6, r7, 7

// fcond 15 (NGT) - Not Greater Than
// CHECK: cmpf.s 15, r6, r7, 0 ; encoding: [0xe6,0x3f,0x30,0x7c]
cmpf.s 15, r6, r7, 0
