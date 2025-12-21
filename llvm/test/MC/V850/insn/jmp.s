// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// JMP - Jump indirect (Format I)
// Syntax: jmp [reg1]
// Operation: PC <- reg1

// CHECK: jmp [r10] ; encoding: [0x6a,0x00]
jmp [r10]

// CHECK: jmp [r31] ; encoding: [0x7f,0x00]
jmp [r31]

// lp is an alias for r31, printed as r31
// CHECK: jmp [r31] ; encoding: [0x7f,0x00]
jmp [lp]
