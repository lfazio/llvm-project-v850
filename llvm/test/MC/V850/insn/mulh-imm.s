// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// MULH imm5, reg2 - Multiply halfword with immediate (Format II)
// Syntax: mulh imm5, reg2
// Operation: reg2 <- reg2[15:0] * sign_extend(imm5)

// CHECK: mulh 0, r10 ; encoding: [0xe0,0x52]
mulh 0, r10

// CHECK: mulh 5, r10 ; encoding: [0xe5,0x52]
mulh 5, r10

// CHECK: mulh -1, r10 ; encoding: [0xff,0x52]
mulh -1, r10

// CHECK: mulh 15, r31 ; encoding: [0xef,0xfa]
mulh 15, r31
