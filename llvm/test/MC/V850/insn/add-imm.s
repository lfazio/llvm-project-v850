// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// ADD imm5, reg2 - Add 5-bit signed immediate to register (Format II)
// Syntax: add imm5, reg2
// Operation: reg2 <- reg2 + sign_extend(imm5)

// CHECK: add 0, r10 ; encoding: [0x40,0x52]
add 0, r10

// CHECK: add 1, r10 ; encoding: [0x41,0x52]
add 1, r10

// CHECK: add 15, r10 ; encoding: [0x4f,0x52]
add 15, r10

// CHECK: add -1, r10 ; encoding: [0x5f,0x52]
add -1, r10

// CHECK: add -16, r10 ; encoding: [0x50,0x52]
add -16, r10

// CHECK: add 5, r31 ; encoding: [0x45,0xfa]
add 5, r31
