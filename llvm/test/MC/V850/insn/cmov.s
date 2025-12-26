// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// CMOV - Conditional move register (Format XI)
// Syntax: cmov cond, reg1, reg2, reg3
// Operation: if (cond) reg3 <- reg1 else reg3 <- reg2

// CHECK: cmov v, r5, r10, r20 ; encoding: [0xe5,0x57,0x20,0xa3]
cmov v, r5, r10, r20

// CHECK: cmov c, r6, r11, r21 ; encoding: [0xe6,0x5f,0x22,0xab]
cmov c, r6, r11, r21

// CHECK: cmov z, r7, r12, r22 ; encoding: [0xe7,0x67,0x24,0xb3]
cmov z, r7, r12, r22

// CHECK: cmov nz, r8, r13, r23 ; encoding: [0xe8,0x6f,0x34,0xbb]
cmov nz, r8, r13, r23

// CHECK: cmov lt, r5, r10, r20 ; encoding: [0xe5,0x57,0x2c,0xa3]
cmov lt, r5, r10, r20

// CHECK: cmov ge, r6, r11, r21 ; encoding: [0xe6,0x5f,0x3c,0xab]
cmov ge, r6, r11, r21

// CMOV - Conditional move immediate (Format XII)
// Syntax: cmov cond, imm5, reg2, reg3
// Operation: if (cond) reg3 <- sign_ext(imm5) else reg3 <- reg2

// CHECK: cmov z, 5, r10, r20 ; encoding: [0xe5,0x57,0x04,0xa3]
cmov z, 5, r10, r20

// CHECK: cmov nz, -16, r15, r25 ; encoding: [0xf0,0x7f,0x14,0xcb]
cmov nz, -16, r15, r25
