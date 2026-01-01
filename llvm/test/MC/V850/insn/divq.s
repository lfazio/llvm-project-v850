// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// DIVQ - Divide word signed quickly (Format XI, 32-bit) - V850E2M only
// High-speed division with variable-step execution
// Syntax: divq reg1, reg2, reg3
// Operation: reg2 <- reg2 / reg1, reg3 <- reg2 % reg1 (signed)

// CHECK: divq r5, r10, r20 ; encoding: [0xe5,0x57,0xfc,0xa2]
divq r5, r10, r20

// CHECK: divq r6, r12, r22 ; encoding: [0xe6,0x67,0xfc,0xb2]
divq r6, r12, r22

// CHECK: divq r7, r14, r24 ; encoding: [0xe7,0x77,0xfc,0xc2]
divq r7, r14, r24
