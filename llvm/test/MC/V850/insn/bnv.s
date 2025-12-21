// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// BNV - Branch if no overflow (Format III)
// Syntax: bnv disp9
// Condition: OV = 0

// CHECK: bnv 0 ; encoding: [0x88,0x05]
bnv 0
