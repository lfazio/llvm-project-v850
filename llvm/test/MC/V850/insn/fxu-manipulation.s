// RUN: llvm-mc -triple=v850 -mcpu=g4mh -show-encoding %s | FileCheck %s

// FXU Vector Manipulation Instructions (RH850G4MH)

// MOVV.W4 - Move vector register
// CHECK: movv.w4 wreg5, wreg10 ; encoding: [0xfe,0x2f,0xa0,0x55]
movv.w4 wreg5, wreg10

// FLPV.S4 - Flip (exchange) vector elements
// CHECK: flpv.s4 2, wreg4, wreg8 ; encoding: [0xfa,0x27,0xa0,0x45]
flpv.s4 2, wreg4, wreg8

// CHECK: flpv.s4 0, wreg0, wreg0 ; encoding: [0xf8,0x07,0xa0,0x05]
flpv.s4 0, wreg0, wreg0

// SHFLV.W4 - Shuffle vector elements (48-bit)
// CHECK: shflv.w4 255, wreg1, wreg2, wreg3 ; encoding: [0xa1,0x6f,0x5d,0x1b,0xff,0x10]
shflv.w4 255, wreg1, wreg2, wreg3
