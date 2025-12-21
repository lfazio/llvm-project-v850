// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// DIVH - Divide halfword (Format I)
// Syntax: divh reg1, reg2
// Operation: reg2 <- reg2 / reg1 (signed halfword)

// CHECK: divh r1, r2 ; encoding: [0x41,0x10]
divh r1, r2

// CHECK: divh r5, r10 ; encoding: [0x45,0x50]
divh r5, r10

// CHECK: divh r31, r31 ; encoding: [0x5f,0xf8]
divh r31, r31
