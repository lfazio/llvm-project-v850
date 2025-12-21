// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// BP - Branch if positive (Format III)
// Syntax: bp disp9
// Condition: S = 0

// CHECK: bp 0 ; encoding: [0x8c,0x05]
bp 0
