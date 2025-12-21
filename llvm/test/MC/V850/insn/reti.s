// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// RETI - Return from interrupt/exception (Format X)
// Syntax: reti
// Operation: Return from exception handler

// CHECK: reti ; encoding: [0xe0,0x07,0x80,0x02]
reti
