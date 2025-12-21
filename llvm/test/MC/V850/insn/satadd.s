// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// SATADD - Saturated add (Format I)
// Syntax: satadd reg1, reg2
// Operation: reg2 <- saturate(reg2 + reg1)

// CHECK: satadd r1, r2 ; encoding: [0xc1,0x10]
satadd r1, r2

// CHECK: satadd r5, r10 ; encoding: [0xc5,0x50]
satadd r5, r10

// CHECK: satadd r31, r31 ; encoding: [0xdf,0xf8]
satadd r31, r31
