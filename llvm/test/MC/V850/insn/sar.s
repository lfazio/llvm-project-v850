// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// SAR - Shift right arithmetic by register (Format IX)
// Syntax: sar reg1, reg2
// Operation: reg2 <- reg2 >> reg1 (arithmetic)

// CHECK: sar r1, r10 ; encoding: [0xe1,0x57,0x80,0x00]
sar r1, r10
