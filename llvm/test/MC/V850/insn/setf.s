// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// SETF - Set flag register (Format IX)
// Syntax: setf cccc, reg2
// Operation: reg2 <- (condition true) ? 1 : 0

// CHECK: setf v, r10 ; encoding: [0xe0,0x57,0x00,0x00]
setf 0, r10
