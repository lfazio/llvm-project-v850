// RUN: llvm-mc -triple=v850 -mcpu=g4mh -show-encoding %s | FileCheck %s

// FXU Exchange Arithmetic Instructions (RH850G4MH)
// Exchange variants swap elements of wreg1 before computing

// ADDXF.S4 - Add with exchange
// CHECK: addxf.s4 wreg2, wreg4, wreg6 ; encoding: [0xe2,0x27,0xc4,0x35]
addxf.s4 wreg2, wreg4, wreg6

// SUBXF.S4 - Subtract with exchange
// CHECK: subxf.s4 wreg1, wreg3, wreg5 ; encoding: [0xe1,0x1f,0xc6,0x2d]
subxf.s4 wreg1, wreg3, wreg5

// MULXF.S4 - Multiply with exchange
// CHECK: mulxf.s4 wreg4, wreg6, wreg8 ; encoding: [0xe4,0x37,0xc8,0x45]
mulxf.s4 wreg4, wreg6, wreg8

// ADDSUBXF.S4 - Add-sub with exchange
// CHECK: addsubxf.s4 wreg2, wreg4, wreg6 ; encoding: [0xe2,0x27,0xd4,0x35]
addsubxf.s4 wreg2, wreg4, wreg6

// SUBADDXF.S4 - Sub-add with exchange
// CHECK: subaddxf.s4 wreg1, wreg3, wreg5 ; encoding: [0xe1,0x1f,0xd6,0x2d]
subaddxf.s4 wreg1, wreg3, wreg5

// ADDSUBNXF.S4 - Add-sub neg with exchange
// CHECK: addsubnxf.s4 wreg4, wreg6, wreg8 ; encoding: [0xe4,0x37,0xdc,0x45]
addsubnxf.s4 wreg4, wreg6, wreg8

// SUBADDNXF.S4 - Sub-add neg with exchange
// CHECK: subaddnxf.s4 wreg2, wreg4, wreg6 ; encoding: [0xe2,0x27,0xde,0x35]
subaddnxf.s4 wreg2, wreg4, wreg6
