// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// SUBR - Reverse subtract (Format I)
// Syntax: subr reg1, reg2
// Operation: reg2 <- reg1 - reg2

// CHECK: subr r0, r0 ; encoding: [0x80,0x01]
subr r0, r0

// CHECK: subr r1, r2 ; encoding: [0x81,0x11]
subr r1, r2

// CHECK: subr r3, r4 ; encoding: [0x83,0x21]
subr r3, r4

// CHECK: subr r31, r31 ; encoding: [0x9f,0xf9]
subr r31, r31
