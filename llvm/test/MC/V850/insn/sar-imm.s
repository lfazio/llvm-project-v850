// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// SAR imm5, reg2 - Shift right arithmetic by immediate (Format II)
// Syntax: sar imm5, reg2
// Operation: reg2 <- reg2 >> imm5 (arithmetic)

// CHECK: sar 0, r10 ; encoding: [0xa0,0x52]
sar 0, r10

// CHECK: sar 1, r10 ; encoding: [0xa1,0x52]
sar 1, r10

// CHECK: sar 16, r10 ; encoding: [0xb0,0x52]
sar 16, r10

// CHECK: sar 31, r10 ; encoding: [0xbf,0x52]
sar 31, r10

// CHECK: sar 5, r31 ; encoding: [0xa5,0xfa]
sar 5, r31
