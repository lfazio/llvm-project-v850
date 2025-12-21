// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// JR - Jump relative (Format V)
// Syntax: jr disp22
// Operation: PC <- PC + sign_extend(disp22)

// CHECK: jr 0 ; encoding: [0xc0,0x05,0x00,0x00]
jr 0
