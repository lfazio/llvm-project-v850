// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// MULU - Multiply unsigned with 9-bit immediate (Format XI-IMM, 32-bit)
// Syntax: mulu imm9, reg2, reg3
// Operation: (reg3, reg2) <- reg2 * zero_ext(imm9)
// Requires: V850E1 or later

// CHECK: mulu 5, r10, r20 ; encoding:
mulu 5, r10, r20

// CHECK: mulu 128, r6, r15 ; encoding:
mulu 128, r6, r15

// CHECK: mulu 511, r1, r2 ; encoding:
mulu 511, r1, r2

