// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// DIVQU - Divide word unsigned quickly (Format XI, 32-bit) - V850E2M only
// High-speed division with variable-step execution
// Syntax: divqu reg1, reg2, reg3
// Operation: reg2 <- reg2 / reg1, reg3 <- reg2 % reg1 (unsigned)

// CHECK: divqu r5, r10, r20 ; encoding: [0xe5,0x57,0xfe,0xa2]
divqu r5, r10, r20

// CHECK: divqu r6, r12, r22 ; encoding: [0xe6,0x67,0xfe,0xb2]
divqu r6, r12, r22

// CHECK: divqu r8, r16, r26 ; encoding: [0xe8,0x87,0xfe,0xd2]
divqu r8, r16, r26
