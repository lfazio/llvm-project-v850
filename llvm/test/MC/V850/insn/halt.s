// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// HALT - Halt CPU (Format X)
// Syntax: halt
// Operation: Stop CPU execution

// CHECK: halt ; encoding: [0xe0,0x17,0x40,0x02]
halt
