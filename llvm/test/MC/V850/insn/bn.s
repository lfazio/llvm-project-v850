// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// BN - Branch if negative (Format III)
// Syntax: bn disp9
// Condition: S = 1

// CHECK: bn 0 ; encoding: [0x84,0x05]
bn 0
