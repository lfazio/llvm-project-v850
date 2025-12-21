// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// SHL - Shift left logical by register (Format IX)
// Syntax: shl reg1, reg2
// Operation: reg2 <- reg2 << reg1

// CHECK: shl r1, r10 ; encoding: [0xe1,0x57,0xc0,0x00]
shl r1, r10
