// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// MUL - Multiply with 9-bit immediate (Format XI-IMM, 32-bit)
// Syntax: mul imm9, reg2, reg3
// Operation: (reg3, reg2) <- reg2 * sign_ext(imm9)
// Requires: V850E1 or later

// CHECK: mul 5, r10, r20 ; encoding:
mul 5, r10, r20

// CHECK: mul -128, r6, r15 ; encoding:
mul -128, r6, r15

// CHECK: mul 255, r1, r2 ; encoding:
mul 255, r1, r2

