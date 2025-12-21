// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// EI - Enable interrupts (Format X)
// Syntax: ei
// Operation: PSW.ID <- 0

// CHECK: ei ; encoding: [0xe0,0x17,0xc0,0x04]
ei
