// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// SUB - Subtract register from register (Format I)
// Syntax: sub reg1, reg2
// Operation: reg2 <- reg2 - reg1

// CHECK: sub r0, r0 ; encoding: [0xa0,0x01]
sub r0, r0

// CHECK: sub r1, r2 ; encoding: [0xa1,0x11]
sub r1, r2

// CHECK: sub r3, r4 ; encoding: [0xa3,0x21]
sub r3, r4

// CHECK: sub r15, r20 ; encoding: [0xaf,0xa1]
sub r15, r20

// CHECK: sub r31, r31 ; encoding: [0xbf,0xf9]
sub r31, r31
