// RUN: llvm-mc -triple=v850 -mcpu=g4mh2 -show-encoding %s | FileCheck %s

// Test RH850G4MH2 virtualization instructions

// HVTRAP vector5
// Encoding: 00000 111111 vvvvv | 0000000100010000

// CHECK: hvtrap 0
// CHECK-SAME: encoding: [0xe0,0x07,0x10,0x01]
hvtrap 0

// CHECK: hvtrap 5
// CHECK-SAME: encoding: [0xe5,0x07,0x10,0x01]
hvtrap 5

// CHECK: hvtrap 31
// CHECK-SAME: encoding: [0xff,0x07,0x10,0x01]
hvtrap 31

// LDM.GSR [reg1]
// Encoding: 00000 111111 RRRRR | 1001100101100000

// CHECK: ldm.gsr [r6]
// CHECK-SAME: encoding: [0xe6,0x07,0x60,0x99]
ldm.gsr [r6]

// CHECK: ldm.gsr [r20]
// CHECK-SAME: encoding: [0xf4,0x07,0x60,0x99]
ldm.gsr [r20]

// STM.GSR [reg1]
// Encoding: 00000 111111 RRRRR | 1001000101100000

// CHECK: stm.gsr [r6]
// CHECK-SAME: encoding: [0xe6,0x07,0x60,0x91]
stm.gsr [r6]

// CHECK: stm.gsr [r20]
// CHECK-SAME: encoding: [0xf4,0x07,0x60,0x91]
stm.gsr [r20]
