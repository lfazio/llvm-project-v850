// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// BGE - Branch if greater or equal (signed) (Format III)
// Syntax: bge disp9
// Condition: (S ^ OV) = 0

// CHECK: bge 0 ; encoding: [0x8e,0x05]
bge 0
