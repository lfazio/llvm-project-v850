// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// SCH0R - Search zero from right (Format XI, 32-bit)
// Syntax: sch0r reg2, reg3
// Operation: reg3 <- position of first 0 bit from LSB (count trailing ones)
// Requires: V850E2 or later

// CHECK: sch0r r10, r20 ; encoding: [0xe0,0x57,0x48,0xa3]
sch0r r10, r20

// CHECK: sch0r r6, r16 ; encoding: [0xe0,0x37,0x48,0x83]
sch0r r6, r16

// CHECK: sch0r r9, r19 ; encoding: [0xe0,0x4f,0x48,0x9b]
sch0r r9, r19
