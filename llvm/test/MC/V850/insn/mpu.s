// RUN: llvm-mc -triple=v850 -mcpu=g4mh2 -show-encoding %s | FileCheck %s

// Test RH850G4MH2 MPU bulk load/store instructions

// LDM.MP [reg1], eh-et
// Encoding: rrrrr111111RRRRR wwwww00101100110
// rrrrr=eh, RRRRR=reg1, wwwww=et

// CHECK: ldm.mp [r6], 0-7
// CHECK-SAME: encoding: [0xe6,0x07,0x66,0x39]
ldm.mp [r6], 0-7

// CHECK: ldm.mp [r10], 2-5
// CHECK-SAME: encoding: [0xea,0x17,0x66,0x29]
ldm.mp [r10], 2-5

// CHECK: ldm.mp [r20], 0-31
// CHECK-SAME: encoding: [0xf4,0x07,0x66,0xf9]
ldm.mp [r20], 0-31

// CHECK: ldm.mp [r1], 15-15
// CHECK-SAME: encoding: [0xe1,0x7f,0x66,0x79]
ldm.mp [r1], 15-15

// STM.MP eh-et, [reg1]
// Encoding: rrrrr111111RRRRR wwwww00101100100
// rrrrr=eh, RRRRR=reg1, wwwww=et

// CHECK: stm.mp 0-7, [r6]
// CHECK-SAME: encoding: [0xe6,0x07,0x64,0x39]
stm.mp 0-7, [r6]

// CHECK: stm.mp 2-5, [r10]
// CHECK-SAME: encoding: [0xea,0x17,0x64,0x29]
stm.mp 2-5, [r10]

// CHECK: stm.mp 0-31, [r20]
// CHECK-SAME: encoding: [0xf4,0x07,0x64,0xf9]
stm.mp 0-31, [r20]
