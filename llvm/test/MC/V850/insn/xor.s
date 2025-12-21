// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// XOR - Bitwise XOR (Format I)
// Syntax: xor reg1, reg2
// Operation: reg2 <- reg2 ^ reg1

// CHECK: xor r0, r0 ; encoding: [0x20,0x01]
xor r0, r0

// CHECK: xor r1, r2 ; encoding: [0x21,0x11]
xor r1, r2

// CHECK: xor r13, r14 ; encoding: [0x2d,0x71]
xor r13, r14

// CHECK: xor r31, r31 ; encoding: [0x3f,0xf9]
xor r31, r31
