// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// BLT - Branch if less than (signed) (Format III)
// Syntax: blt disp9
// Condition: (S ^ OV) = 1

// CHECK: blt 0 ; encoding: [0x86,0x05]
blt 0
