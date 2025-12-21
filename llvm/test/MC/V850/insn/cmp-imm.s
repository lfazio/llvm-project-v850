// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// CMP imm5, reg2 - Compare with 5-bit signed immediate (Format II)
// Syntax: cmp imm5, reg2
// Operation: flags <- (reg2 - sign_extend(imm5))

// CHECK: cmp 0, r10 ; encoding: [0x60,0x52]
cmp 0, r10

// CHECK: cmp 5, r10 ; encoding: [0x65,0x52]
cmp 5, r10

// CHECK: cmp -1, r10 ; encoding: [0x7f,0x52]
cmp -1, r10

// CHECK: cmp 15, r31 ; encoding: [0x6f,0xfa]
cmp 15, r31
