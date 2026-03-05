// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding < %s | FileCheck %s

// CHECK: mac r6, r7, r8, r9
// CHECK: encoding: [0xe6,0x3f,0xc9,0x43]
mac r6, r7, r8, r9

// CHECK: mac r1, r2, r3, r4
// CHECK: encoding: [0xe1,0x17,0xc4,0x1b]
mac r1, r2, r3, r4

// CHECK: mac r10, r11, r12, r13
// CHECK: encoding: [0xea,0x5f,0xcd,0x63]
mac r10, r11, r12, r13
