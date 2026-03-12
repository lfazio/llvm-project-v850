// RUN: llvm-mc -triple=v850 -mcpu=g4mh -show-encoding %s | FileCheck %s

// FXU Compound Arithmetic Instructions (RH850G4MH)
// These operate on pairs differently: upper pair gets one op, lower pair another

// ADDSUBF.S4 - [3:2]=add, [1:0]=sub
// CHECK: addsubf.s4 wreg2, wreg4, wreg6 ; encoding: [0xe2,0x27,0xb0,0x35]
addsubf.s4 wreg2, wreg4, wreg6

// SUBADDF.S4 - [3:2]=sub, [1:0]=add
// CHECK: subaddf.s4 wreg1, wreg3, wreg5 ; encoding: [0xe1,0x1f,0xb2,0x2d]
subaddf.s4 wreg1, wreg3, wreg5

// ADDSUBNF.S4 - [3:2]=add, [1:0]=sub (negated)
// CHECK: addsubnf.s4 wreg4, wreg6, wreg8 ; encoding: [0xe4,0x37,0xb8,0x45]
addsubnf.s4 wreg4, wreg6, wreg8

// SUBADDNF.S4 - [3:2]=sub, [1:0]=add (negated)
// CHECK: subaddnf.s4 wreg2, wreg4, wreg6 ; encoding: [0xe2,0x27,0xba,0x35]
subaddnf.s4 wreg2, wreg4, wreg6
