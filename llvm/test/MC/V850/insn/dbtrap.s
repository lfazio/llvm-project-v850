// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// DBTRAP - Debug trap (16-bit)
// Syntax: dbtrap
// Operation: DBPC <- PC + 2, DBPSW <- PSW, enter debug mode
// Requires: V850E1 or later

// CHECK: dbtrap ; encoding: [0x40,0xf8]
dbtrap
