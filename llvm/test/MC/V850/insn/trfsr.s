// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// TRFSR - Transfer floating-point status to PSW.Z

// CHECK: trfsr 0 ; encoding: [0xe0,0x07,0x00,0x04]
trfsr 0

// CHECK: trfsr 3 ; encoding: [0xe0,0x07,0x06,0x04]
trfsr 3

// CHECK: trfsr 7 ; encoding: [0xe0,0x07,0x0e,0x04]
trfsr 7
