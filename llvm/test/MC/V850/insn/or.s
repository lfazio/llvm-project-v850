// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// OR - Bitwise OR (Format I)
// Syntax: or reg1, reg2
// Operation: reg2 <- reg2 | reg1

// CHECK: or r0, r0 ; encoding: [0x00,0x01]
or r0, r0

// CHECK: or r1, r2 ; encoding: [0x01,0x11]
or r1, r2

// CHECK: or r9, r10 ; encoding: [0x09,0x51]
or r9, r10

// CHECK: or r31, r31 ; encoding: [0x1f,0xf9]
or r31, r31
