// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// BC - Branch if carry (also BL - Branch if lower) (Format III)
// Syntax: bc disp9
// Condition: CY = 1

// CHECK: bc 0 ; encoding: [0x81,0x05]
bc 0
