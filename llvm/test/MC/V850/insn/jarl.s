// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// JARL - Jump and register link (Format V)
// Syntax: jarl disp22, reg2
// Operation: reg2 <- PC + 4; PC <- PC + sign_extend(disp22)

// CHECK: jarl 0, r10 ; encoding: [0xc0,0x55,0x00,0x00]
jarl 0, r10
