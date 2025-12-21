// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// BV - Branch if overflow (Format III)
// Syntax: bv disp9
// Condition: OV = 1

// CHECK: bv 0 ; encoding: [0x80,0x05]
bv 0
