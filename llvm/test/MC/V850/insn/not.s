// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// NOT - Bitwise NOT (Format I)
// Syntax: not reg1, reg2
// Operation: reg2 <- ~reg1

// CHECK: not r0, r0 ; encoding: [0x20,0x00]
not r0, r0

// CHECK: not r1, r2 ; encoding: [0x21,0x10]
not r1, r2

// CHECK: not r7, r8 ; encoding: [0x27,0x40]
not r7, r8

// CHECK: not r31, r31 ; encoding: [0x3f,0xf8]
not r31, r31
