// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// MOV imm5, reg2 - Move 5-bit signed immediate to register (Format II)
// Syntax: mov imm5, reg2
// Operation: reg2 <- sign_extend(imm5)

// CHECK: mov 0, r10 ; encoding: [0x00,0x52]
mov 0, r10

// CHECK: mov 1, r10 ; encoding: [0x01,0x52]
mov 1, r10

// CHECK: mov 15, r10 ; encoding: [0x0f,0x52]
mov 15, r10

// CHECK: mov -1, r10 ; encoding: [0x1f,0x52]
mov -1, r10

// CHECK: mov -16, r10 ; encoding: [0x10,0x52]
mov -16, r10

// CHECK: mov 5, r31 ; encoding: [0x05,0xfa]
mov 5, r31
