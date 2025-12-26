// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// DBRET - Return from debug trap (Format X, 32-bit)
// Syntax: dbret
// Operation: PC <- DBPC, PSW <- DBPSW, exit debug mode
// Requires: V850E1 or later

// CHECK: dbret ; encoding: [0xe6,0x0f,0x20,0x02]
dbret
