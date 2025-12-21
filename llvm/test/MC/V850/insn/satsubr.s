// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// SATSUBR - Saturated subtract reverse (Format I)
// Syntax: satsubr reg1, reg2
// Operation: reg2 <- saturate(reg1 - reg2)

// CHECK: satsubr r1, r2 ; encoding: [0x81,0x10]
satsubr r1, r2

// CHECK: satsubr r5, r10 ; encoding: [0x85,0x50]
satsubr r5, r10

// CHECK: satsubr r31, r31 ; encoding: [0x9f,0xf8]
satsubr r31, r31
