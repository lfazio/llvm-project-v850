// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// CALLT - Call with table look up (16-bit)
// Syntax: callt imm6
// Operation: CTPC <- PC + 2, CTPSW <- PSW, PC <- CTBP + mem[CTBP + imm6*2]

// CHECK: callt 0 ; encoding: [0x00,0x02]
callt 0

// CHECK: callt 1 ; encoding: [0x01,0x02]
callt 1

// CHECK: callt 32 ; encoding: [0x20,0x02]
callt 32

// CHECK: callt 63 ; encoding: [0x3f,0x02]
callt 63
