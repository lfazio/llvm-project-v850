// RUN: llvm-mc -triple=v850 -mcpu=g4mh -show-encoding %s | FileCheck %s

// FXU Reduction Instructions (RH850G4MH)
// Reduce 4 elements to scalar in element 0

// ADDRF.S4 - Reduction add
// CHECK: addrf.s4 wreg2, wreg4 ; encoding: [0xe0,0x17,0xb4,0x25]
addrf.s4 wreg2, wreg4

// SUBRF.S4 - Reduction subtract
// CHECK: subrf.s4 wreg4, wreg6 ; encoding: [0xe0,0x27,0xb6,0x35]
subrf.s4 wreg4, wreg6

// MULRF.S4 - Reduction multiply
// CHECK: mulrf.s4 wreg6, wreg8 ; encoding: [0xe0,0x37,0xb8,0x45]
mulrf.s4 wreg6, wreg8

// MAXRF.S4 - Reduction maximum
// CHECK: maxrf.s4 wreg8, wreg10 ; encoding: [0xe0,0x47,0xba,0x55]
maxrf.s4 wreg8, wreg10

// MINRF.S4 - Reduction minimum
// CHECK: minrf.s4 wreg10, wreg12 ; encoding: [0xe0,0x57,0xbc,0x65]
minrf.s4 wreg10, wreg12
