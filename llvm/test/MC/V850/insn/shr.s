// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// SHR - Shift right logical by register (Format IX)
// Syntax: shr reg1, reg2
// Operation: reg2 <- reg2 >> reg1 (logical)

// CHECK: shr r1, r10 ; encoding: [0xe1,0x57,0x40,0x00]
shr r1, r10
