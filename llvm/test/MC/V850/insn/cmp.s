// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// CMP - Compare registers (Format I)
// Syntax: cmp reg1, reg2
// Operation: Compare reg2 with reg1, set flags

// CHECK: cmp r0, r0 ; encoding: [0xe0,0x01]
cmp r0, r0

// CHECK: cmp r1, r2 ; encoding: [0xe1,0x11]
cmp r1, r2

// CHECK: cmp r3, r4 ; encoding: [0xe3,0x21]
cmp r3, r4

// CHECK: cmp r31, r31 ; encoding: [0xff,0xf9]
cmp r31, r31
