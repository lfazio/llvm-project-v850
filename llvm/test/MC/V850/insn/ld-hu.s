// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// LD.HU - Load halfword unsigned (Format VII, 32-bit)
// Syntax: ld.hu disp16[reg1], reg2
// Operation: reg2 <- zero_extend(mem[reg1 + disp16])

// CHECK: ld.hu 0[r6], r10 ; encoding: [0xe6,0x57,0x00,0x00]
ld.hu 0[r6], r10

// CHECK: ld.hu 100[r10], r20 ; encoding: [0xea,0xa7,0x64,0x00]
ld.hu 100[r10], r20

// CHECK: ld.hu -100[r15], r25 ; encoding: [0xef,0xcf,0x9c,0xff]
ld.hu -100[r15], r25
