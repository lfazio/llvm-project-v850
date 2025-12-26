// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// SWITCH - Jump with table look up (Format I variant, reg2=0)
// Syntax: switch reg1
// Operation: PC <- PC + 2 + (sign_ext(mem[PC + 2 + reg1*2]) << 1)

// CHECK: switch r6 ; encoding: [0x46,0x00]
switch r6

// CHECK: switch r10 ; encoding: [0x4a,0x00]
switch r10

// CHECK: switch r20 ; encoding: [0x54,0x00]
switch r20
