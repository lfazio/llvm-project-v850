// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// FETRAP - FE Level Software Trap (16-bit)
// Triggers an FE-level software exception
// Opcode: 0vvvv00001000000 where vvvv is vector4 (1-15, 0 is reserved)
// Requires: V850E2M or later

// CHECK: fetrap 1 ; encoding: [0x40,0x08]
fetrap 1

// CHECK: fetrap 2 ; encoding: [0x40,0x10]
fetrap 2

// CHECK: fetrap 7 ; encoding: [0x40,0x38]
fetrap 7

// CHECK: fetrap 15 ; encoding: [0x40,0x78]
fetrap 15
