// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// MOVEA - Move effective address (Format VI)
// Syntax: movea imm16, reg1, reg2
// Operation: reg2 <- reg1 + sign_extend(imm16)

// CHECK: movea 0, r0, r10 ; encoding: [0x20,0x56,0x00,0x00]
movea 0, r0, r10
