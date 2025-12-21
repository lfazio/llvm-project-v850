// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// SATSUB - Saturated subtract (Format I)
// Syntax: satsub reg1, reg2
// Operation: reg2 <- saturate(reg2 - reg1)

// CHECK: satsub r1, r2 ; encoding: [0xa1,0x10]
satsub r1, r2

// CHECK: satsub r5, r10 ; encoding: [0xa5,0x50]
satsub r5, r10

// CHECK: satsub r31, r31 ; encoding: [0xbf,0xf8]
satsub r31, r31
