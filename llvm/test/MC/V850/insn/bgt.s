// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// BGT - Branch if greater than (signed) (Format III)
// Syntax: bgt disp9
// Condition: ((S ^ OV) | Z) = 0

// CHECK: bgt 0 ; encoding: [0x8f,0x05]
bgt 0
