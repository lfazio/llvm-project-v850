// RUN: llvm-mc -triple=v850 -mcpu=g4mh -show-encoding %s | FileCheck %s

// FXU Comparison Instructions (RH850G4MH)

// CMPF.S4 - Compare 4 float pairs, store mask in wreg3
// CHECK: cmpf.s4 5, wreg2, wreg4, wreg6 ; encoding: [0xe2,0x27,0x8a,0x35]
cmpf.s4 5, wreg2, wreg4, wreg6

// CMOVF.W4 - Conditional move based on FXSR compare flags (48-bit)
// CHECK: cmovf.w4 3, wreg1, wreg2, wreg3, wreg4 ; encoding: [0xa6,0x07,0x1d,0x1e,0x04,0x10]
cmovf.w4 3, wreg1, wreg2, wreg3, wreg4

// TRFSRV.W4 - Transfer FXU status register to vector
// CHECK: trfsrv.w4 3, wreg8 ; encoding: [0xff,0x1f,0xa0,0x45]
trfsrv.w4 3, wreg8
