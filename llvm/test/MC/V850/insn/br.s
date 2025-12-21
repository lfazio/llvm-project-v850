// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// BR - Branch always (unconditional short branch) (Format III)
// Syntax: br disp9
// Condition: always

// CHECK: br 0 ; encoding: [0x85,0x05]
br 0
