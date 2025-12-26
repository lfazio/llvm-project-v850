// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// PREPARE - Push registers and allocate stack frame (Format XIII, 32-bit)
// Syntax: prepare list12, imm5
// list12: 12-bit mask for registers r20-r31 (bit0=r30/EP, bit11=r31/LP)
// imm5: stack frame size = imm5 * 4 bytes

// CHECK: prepare 0, 0 ; encoding: [0x40,0x06,0x00,0x00]
prepare 0, 0

// CHECK: prepare 1, 4 ; encoding: [0x49,0x06,0x00,0x00]
prepare 1, 4

// CHECK: prepare 4095, 31 ; encoding: [0x7f,0x06,0xe0,0xff]
prepare 4095, 31
