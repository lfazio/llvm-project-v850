// RUN: llvm-mc -triple=v850 -mcpu=g4mh -show-encoding %s | FileCheck %s

// FXU Vector Arithmetic Instructions (RH850G4MH)

// --- 2OP arithmetic (5 instructions) ---

// ABSF.S4 - Absolute value (4x)
// CHECK: absf.s4 wreg4, wreg8 ; encoding: [0xf0,0x27,0xa0,0x45]
absf.s4 wreg4, wreg8

// NEGF.S4 - Negate (4x)
// CHECK: negf.s4 wreg2, wreg10 ; encoding: [0xf1,0x17,0xa0,0x55]
negf.s4 wreg2, wreg10

// SQRTF.S4 - Square root (4x)
// CHECK: sqrtf.s4 wreg6, wreg12 ; encoding: [0xf2,0x37,0xa0,0x65]
sqrtf.s4 wreg6, wreg12

// RECIPF.S4 - Reciprocal (4x)
// CHECK: recipf.s4 wreg8, wreg14 ; encoding: [0xf3,0x47,0xa0,0x75]
recipf.s4 wreg8, wreg14

// RSQRTF.S4 - Reciprocal square root (4x)
// CHECK: rsqrtf.s4 wreg10, wreg16 ; encoding: [0xf4,0x57,0xa0,0x85]
rsqrtf.s4 wreg10, wreg16

// --- 3OP arithmetic (6 instructions) ---

// ADDF.S4 - Add (4x)
// CHECK: addf.s4 wreg2, wreg4, wreg6 ; encoding: [0xe2,0x27,0xa4,0x35]
addf.s4 wreg2, wreg4, wreg6

// SUBF.S4 - Subtract (4x)
// CHECK: subf.s4 wreg1, wreg3, wreg5 ; encoding: [0xe1,0x1f,0xa6,0x2d]
subf.s4 wreg1, wreg3, wreg5

// MULF.S4 - Multiply (4x)
// CHECK: mulf.s4 wreg4, wreg6, wreg8 ; encoding: [0xe4,0x37,0xa8,0x45]
mulf.s4 wreg4, wreg6, wreg8

// MAXF.S4 - Maximum (4x)
// CHECK: maxf.s4 wreg2, wreg4, wreg6 ; encoding: [0xe2,0x27,0xaa,0x35]
maxf.s4 wreg2, wreg4, wreg6

// MINF.S4 - Minimum (4x)
// CHECK: minf.s4 wreg6, wreg8, wreg10 ; encoding: [0xe6,0x47,0xac,0x55]
minf.s4 wreg6, wreg8, wreg10

// DIVF.S4 - Divide (4x)
// CHECK: divf.s4 wreg2, wreg4, wreg6 ; encoding: [0xe2,0x27,0xae,0x35]
divf.s4 wreg2, wreg4, wreg6
