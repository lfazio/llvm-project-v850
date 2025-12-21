// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// XORI - XOR with 16-bit immediate (Format VI)
// Syntax: xori imm16, reg1, reg2
// Operation: reg2 <- reg1 ^ zero_extend(imm16)

// CHECK: xori 0, r0, r10 ; encoding: [0xa0,0x56,0x00,0x00]
xori 0, r0, r10
