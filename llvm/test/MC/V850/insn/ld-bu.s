// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// LD.BU - Load byte unsigned (Format VII, 32-bit)
// Syntax: ld.bu disp16[reg1], reg2
// Operation: reg2 <- zero_extend(mem[reg1 + disp16])

// CHECK: ld.bu 0[r6], r10 ; encoding: [0x86,0x57,0x00,0x00]
ld.bu 0[r6], r10

// CHECK: ld.bu 100[r10], r20 ; encoding: [0x8a,0xa7,0x64,0x00]
ld.bu 100[r10], r20

// CHECK: ld.bu -50[r15], r25 ; encoding: [0x8f,0xcf,0xce,0xff]
ld.bu -50[r15], r25
