// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// CAXI - Compare and Exchange for Interlock (32-bit)
// Atomic compare-and-swap operation
// Syntax: caxi [reg1], reg2, reg3
// Operation:
//   1. Read word at address in reg1 (lower 2 bits masked to 0)
//   2. Compare with reg2, set flags based on (reg2 - read_value)
//   3. If equal: store reg3 to memory, else: store read_value back
//   4. Store read_value to reg3
// Requires: V850E2M or later

// CHECK: caxi [r5], r10, r15 ; encoding: [0xe5,0x57,0xee,0x78]
caxi [r5], r10, r15

// CHECK: caxi [r1], r2, r3 ; encoding: [0xe1,0x17,0xee,0x18]
caxi [r1], r2, r3

// CHECK: caxi [r10], r20, r25 ; encoding: [0xea,0xa7,0xee,0xc8]
caxi [r10], r20, r25

// CHECK: caxi [r31], r0, r1 ; encoding: [0xff,0x07,0xee,0x08]
caxi [r31], r0, r1
