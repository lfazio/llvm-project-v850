// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// ORI - OR with 16-bit immediate (Format VI)
// Syntax: ori imm16, reg1, reg2
// Operation: reg2 <- reg1 | zero_extend(imm16)

// CHECK: ori 0, r0, r10 ; encoding: [0x80,0x56,0x00,0x00]
ori 0, r0, r10
