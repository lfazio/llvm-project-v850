// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// SHL imm5, reg2 - Shift left logical by immediate (Format II)
// Syntax: shl imm5, reg2
// Operation: reg2 <- reg2 << imm5

// CHECK: shl 0, r10 ; encoding: [0xc0,0x52]
shl 0, r10

// CHECK: shl 1, r10 ; encoding: [0xc1,0x52]
shl 1, r10

// CHECK: shl 16, r10 ; encoding: [0xd0,0x52]
shl 16, r10

// CHECK: shl 31, r10 ; encoding: [0xdf,0x52]
shl 31, r10

// CHECK: shl 5, r31 ; encoding: [0xc5,0xfa]
shl 5, r31
