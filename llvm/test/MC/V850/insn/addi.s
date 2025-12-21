// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// ADDI - Add 16-bit immediate (Format VI)
// Syntax: addi imm16, reg1, reg2
// Operation: reg2 <- reg1 + sign_extend(imm16)

// CHECK: addi 0, r0, r10 ; encoding: [0x00,0x56,0x00,0x00]
addi 0, r0, r10
