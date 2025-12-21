// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// MOV - Move register to register (Format I)
// Syntax: mov reg1, reg2
// Operation: reg2 <- reg1

// CHECK: mov r0, r0 ; encoding: [0x00,0x00]
mov r0, r0

// CHECK: mov r1, r2 ; encoding: [0x01,0x10]
mov r1, r2

// CHECK: mov r5, r6 ; encoding: [0x05,0x30]
mov r5, r6

// CHECK: mov r15, r20 ; encoding: [0x0f,0xa0]
mov r15, r20

// CHECK: mov r31, r31 ; encoding: [0x1f,0xf8]
mov r31, r31
