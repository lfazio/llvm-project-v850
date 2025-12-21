// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// MULHI - Multiply high immediate (Format VI)
// Syntax: mulhi imm16, reg1, reg2
// Operation: reg2 <- reg1[15:0] * imm16

// CHECK: mulhi 0, r0, r10 ; encoding: [0xe0,0x56,0x00,0x00]
mulhi 0, r0, r10
