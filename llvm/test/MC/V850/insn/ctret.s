// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// CTRET - Return from CALLT (Format X, 32-bit)
// Syntax: ctret
// Operation: PC <- CTPC, PSW <- CTPSW

// CHECK: ctret ; encoding: [0xe4,0x0f,0x20,0x02]
ctret
