// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// BZ - Branch if zero (also BE - Branch if equal) (Format III)
// Syntax: bz disp9
// Condition: Z = 1

// CHECK: bz 0 ; encoding: [0x82,0x05]
bz 0
