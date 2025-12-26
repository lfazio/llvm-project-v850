// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// SASF - Shift and set flag (Format IX, 32-bit)
// Syntax: sasf cond, reg2
// Operation: reg2 <- (reg2 << 1) | cond_result

// CHECK: sasf v, r10 ; encoding: [0xe0,0x57,0x00,0x01]
sasf v, r10

// CHECK: sasf c, r15 ; encoding: [0xe1,0x7f,0x00,0x01]
sasf c, r15

// CHECK: sasf z, r20 ; encoding: [0xe2,0xa7,0x00,0x01]
sasf z, r20

// CHECK: sasf nz, r25 ; encoding: [0xea,0xcf,0x00,0x01]
sasf nz, r25

// CHECK: sasf lt, r10 ; encoding: [0xe6,0x57,0x00,0x01]
sasf lt, r10

// CHECK: sasf ge, r15 ; encoding: [0xee,0x7f,0x00,0x01]
sasf ge, r15
