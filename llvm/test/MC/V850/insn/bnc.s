// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// BNC - Branch if no carry (also BNL - Branch if not lower) (Format III)
// Syntax: bnc disp9
// Condition: CY = 0

// CHECK: bnc 0 ; encoding: [0x89,0x05]
bnc 0
