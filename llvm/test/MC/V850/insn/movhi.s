// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// MOVHI - Move high immediate (Format VI)
// Syntax: movhi imm16, reg1, reg2
// Operation: reg2 <- reg1 + (imm16 << 16)

// CHECK: movhi 0, r0, r10 ; encoding: [0x40,0x56,0x00,0x00]
movhi 0, r0, r10
