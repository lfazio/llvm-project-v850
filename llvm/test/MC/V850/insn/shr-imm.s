// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// SHR imm5, reg2 - Shift right logical by immediate (Format II)
// Syntax: shr imm5, reg2
// Operation: reg2 <- reg2 >> imm5 (logical)

// CHECK: shr 0, r10 ; encoding: [0x80,0x52]
shr 0, r10

// CHECK: shr 1, r10 ; encoding: [0x81,0x52]
shr 1, r10

// CHECK: shr 16, r10 ; encoding: [0x90,0x52]
shr 16, r10

// CHECK: shr 31, r10 ; encoding: [0x9f,0x52]
shr 31, r10

// CHECK: shr 5, r31 ; encoding: [0x85,0xfa]
shr 5, r31
