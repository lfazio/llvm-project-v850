// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CMPF.D - Double-precision floating-point compare
// Syntax: cmpf.d fcond, reg1, reg2, fcbit
// Sets FPCC[fcbit] based on comparing reg2 to reg1 using condition fcond
// Note: reg1 and reg2 must be even registers (lower register of pair)

// fcond 0 (F) - False
// CHECK: cmpf.d 0, r6, r8, 0 ; encoding: [0xe6,0x47,0x31,0x04]
cmpf.d 0, r6, r8, 0

// fcond 2 (EQ) - Equal
// CHECK: cmpf.d 2, r6, r8, 0 ; encoding: [0xe6,0x47,0x31,0x14]
cmpf.d 2, r6, r8, 0

// fcond 4 (OLT) - Ordered Less Than
// CHECK: cmpf.d 4, r10, r12, 1 ; encoding: [0xea,0x67,0x33,0x24]
cmpf.d 4, r10, r12, 1

// fcond 6 (OLE) - Ordered Less or Equal
// CHECK: cmpf.d 6, r6, r8, 2 ; encoding: [0xe6,0x47,0x35,0x34]
cmpf.d 6, r6, r8, 2

// fcond 12 (LT) - Less Than
// CHECK: cmpf.d 12, r6, r8, 3 ; encoding: [0xe6,0x47,0x37,0x64]
cmpf.d 12, r6, r8, 3

// fcond 14 (LE) - Less or Equal
// CHECK: cmpf.d 14, r6, r8, 7 ; encoding: [0xe6,0x47,0x3f,0x74]
cmpf.d 14, r6, r8, 7

// fcond 15 (NGT) - Not Greater Than
// CHECK: cmpf.d 15, r6, r8, 0 ; encoding: [0xe6,0x47,0x31,0x7c]
cmpf.d 15, r6, r8, 0
