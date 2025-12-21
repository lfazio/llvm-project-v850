// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// ADD - Add register to register (Format I)
// Syntax: add reg1, reg2
// Operation: reg2 <- reg2 + reg1

// CHECK: add r0, r0 ; encoding: [0xc0,0x01]
add r0, r0

// CHECK: add r1, r2 ; encoding: [0xc1,0x11]
add r1, r2

// CHECK: add r5, r10 ; encoding: [0xc5,0x51]
add r5, r10

// CHECK: add r15, r20 ; encoding: [0xcf,0xa1]
add r15, r20

// CHECK: add r31, r31 ; encoding: [0xdf,0xf9]
add r31, r31
