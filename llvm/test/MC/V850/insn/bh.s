// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// BH - Branch if higher (Format III)
// Syntax: bh disp9
// Condition: (CY | Z) = 0

// CHECK: bh 0 ; encoding: [0x8b,0x05]
bh 0
