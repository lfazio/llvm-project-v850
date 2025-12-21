// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// AND - Bitwise AND (Format I)
// Syntax: and reg1, reg2
// Operation: reg2 <- reg2 & reg1

// CHECK: and r0, r0 ; encoding: [0x40,0x01]
and r0, r0

// CHECK: and r1, r2 ; encoding: [0x41,0x11]
and r1, r2

// CHECK: and r11, r12 ; encoding: [0x4b,0x61]
and r11, r12

// CHECK: and r31, r31 ; encoding: [0x5f,0xf9]
and r31, r31
