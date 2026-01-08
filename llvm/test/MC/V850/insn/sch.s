// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// SCH1L - Search one from left (count leading zeros)
// Opcode: 111111, sub-op: 011010, sub-id: 01110

// CHECK: sch1l r6, r7 ; encoding: [0xe0,0x37,0x4e,0x3b]
sch1l r6, r7

// CHECK: sch1l r10, r11 ; encoding: [0xe0,0x57,0x4e,0x5b]
sch1l r10, r11

// CHECK: sch1l r0, r1 ; encoding: [0xe0,0x07,0x4e,0x0b]
sch1l r0, r1

// SCH1R - Search one from right (count trailing zeros)
// Opcode: 111111, sub-op: 011010, sub-id: 01010

// CHECK: sch1r r6, r7 ; encoding: [0xe0,0x37,0x4a,0x3b]
sch1r r6, r7

// CHECK: sch1r r10, r11 ; encoding: [0xe0,0x57,0x4a,0x5b]
sch1r r10, r11

// CHECK: sch1r r0, r1 ; encoding: [0xe0,0x07,0x4a,0x0b]
sch1r r0, r1

// SCH0L - Search zero from left (count leading ones)
// Opcode: 111111, sub-op: 011010, sub-id: 01100

// CHECK: sch0l r6, r7 ; encoding: [0xe0,0x37,0x4c,0x3b]
sch0l r6, r7

// CHECK: sch0l r10, r11 ; encoding: [0xe0,0x57,0x4c,0x5b]
sch0l r10, r11

// CHECK: sch0l r0, r1 ; encoding: [0xe0,0x07,0x4c,0x0b]
sch0l r0, r1

// SCH0R - Search zero from right (count trailing ones)
// Opcode: 111111, sub-op: 011010, sub-id: 01000

// CHECK: sch0r r6, r7 ; encoding: [0xe0,0x37,0x48,0x3b]
sch0r r6, r7

// CHECK: sch0r r10, r11 ; encoding: [0xe0,0x57,0x48,0x5b]
sch0r r10, r11

// CHECK: sch0r r0, r1 ; encoding: [0xe0,0x07,0x48,0x0b]
sch0r r0, r1
