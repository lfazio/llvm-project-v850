// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// SATADD imm5, reg2 - Saturated add with 5-bit immediate (Format II)
// Syntax: satadd imm5, reg2
// Operation: reg2 <- saturate(reg2 + sign_extend(imm5))

// CHECK: satadd 0, r10 ; encoding: [0x20,0x52]
satadd 0, r10

// CHECK: satadd 5, r10 ; encoding: [0x25,0x52]
satadd 5, r10

// CHECK: satadd -1, r10 ; encoding: [0x3f,0x52]
satadd -1, r10

// CHECK: satadd 15, r31 ; encoding: [0x2f,0xfa]
satadd 15, r31
