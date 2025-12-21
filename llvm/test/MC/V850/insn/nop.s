// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// NOP - No operation (encoded as MOV r0, r0)

// CHECK: nop ; encoding: [0x00,0x00]
nop
