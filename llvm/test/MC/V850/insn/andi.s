// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// ANDI - AND with 16-bit immediate (Format VI)
// Syntax: andi imm16, reg1, reg2
// Operation: reg2 <- reg1 & zero_extend(imm16)

// CHECK: andi 0, r0, r10 ; encoding: [0xc0,0x56,0x00,0x00]
andi 0, r0, r10
