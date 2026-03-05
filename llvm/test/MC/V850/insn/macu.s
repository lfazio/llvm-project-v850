// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding < %s | FileCheck %s

// CHECK: macu r6, r7, r8, r9
// CHECK: encoding: [0xe6,0x3f,0xe9,0x43]
macu r6, r7, r8, r9

// CHECK: macu r1, r2, r3, r4
// CHECK: encoding: [0xe1,0x17,0xe4,0x1b]
macu r1, r2, r3, r4

// CHECK: macu r10, r11, r12, r13
// CHECK: encoding: [0xea,0x5f,0xed,0x63]
macu r10, r11, r12, r13
