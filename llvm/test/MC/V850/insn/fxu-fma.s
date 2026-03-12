// RUN: llvm-mc -triple=v850 -mcpu=g4mh -show-encoding %s | FileCheck %s

// FXU Fused Multiply-Add Instructions (RH850G4MH)

// FMAF.S4 - wreg3 = (wreg2 * wreg1) + wreg3
// CHECK: fmaf.s4 wreg1, wreg2, wreg3 ; encoding: [0xe1,0x17,0xc0,0x1c]
fmaf.s4 wreg1, wreg2, wreg3

// FMSF.S4 - wreg3 = (wreg2 * wreg1) - wreg3
// CHECK: fmsf.s4 wreg4, wreg6, wreg8 ; encoding: [0xe4,0x37,0xc2,0x44]
fmsf.s4 wreg4, wreg6, wreg8

// FNMAF.S4 - wreg3 = -(wreg2 * wreg1) + wreg3
// CHECK: fnmaf.s4 wreg2, wreg4, wreg6 ; encoding: [0xe2,0x27,0xc4,0x34]
fnmaf.s4 wreg2, wreg4, wreg6

// FNMSF.S4 - wreg3 = -(wreg2 * wreg1) - wreg3
// CHECK: fnmsf.s4 wreg1, wreg3, wreg5 ; encoding: [0xe1,0x1f,0xc6,0x2c]
fnmsf.s4 wreg1, wreg3, wreg5
