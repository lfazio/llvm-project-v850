// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// DI - Disable interrupts (Format X)
// Syntax: di
// Operation: PSW.ID <- 1

// CHECK: di ; encoding: [0xe0,0x17,0xc0,0x02]
di
