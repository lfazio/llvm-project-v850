// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// SATSUBI - Saturated subtract immediate (Format VI)
// Syntax: satsubi imm16, reg1, reg2
// Operation: reg2 <- saturate(reg1 - sign_extend(imm16))

// CHECK: satsubi 0, r0, r10 ; encoding: [0x60,0x56,0x00,0x00]
satsubi 0, r0, r10
