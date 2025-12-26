// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// DISPOSE - Pop registers and deallocate stack frame (Format XIII, 32-bit)
// Syntax: dispose imm5, list12
// imm5: stack frame size = imm5 * 4 bytes
// list12: 12-bit mask for registers r20-r31 (bit0=r30/EP, bit11=r31/LP)

// Note: DISPOSE without jump register has same encoding as PREPARE
// (disassembles as PREPARE)

// DISPOSE with jump register has different encoding (reg1 != 0)
// CHECK: dispose 4, 1, [r31] ; encoding: [0x49,0x06,0x1f,0x00]
dispose 4, 1, [r31]
