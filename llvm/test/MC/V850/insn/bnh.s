// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// BNH - Branch if not higher (Format III)
// Syntax: bnh disp9
// Condition: (CY | Z) = 1

// CHECK: bnh 0 ; encoding: [0x83,0x05]
bnh 0
