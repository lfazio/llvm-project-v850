// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// BNZ - Branch if not zero (also BNE - Branch if not equal) (Format III)
// Syntax: bnz disp9
// Condition: Z = 0

// CHECK: bnz 0 ; encoding: [0x8a,0x05]
bnz 0
