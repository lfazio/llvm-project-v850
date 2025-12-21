// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// BSA - Branch if saturated (Format III)
// Syntax: bsa disp9
// Condition: SAT = 1

// CHECK: bsa 0 ; encoding: [0x8d,0x05]
bsa 0
