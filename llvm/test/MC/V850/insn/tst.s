// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// TST - Test (AND without storing result) (Format I)
// Syntax: tst reg1, reg2
// Operation: flags <- (reg2 & reg1)

// CHECK: tst r0, r0 ; encoding: [0x60,0x01]
tst r0, r0

// CHECK: tst r1, r2 ; encoding: [0x61,0x11]
tst r1, r2

// CHECK: tst r15, r20 ; encoding: [0x6f,0xa1]
tst r15, r20

// CHECK: tst r31, r31 ; encoding: [0x7f,0xf9]
tst r31, r31
