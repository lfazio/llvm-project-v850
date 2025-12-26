// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// SLD.HU - Short load halfword unsigned (Format IV-HU, 16-bit)
// Syntax: sld.hu disp5, reg2 (EP is implicit base)
// Operation: reg2 <- zero_extend(mem[EP + disp5])
// Displacement range: 0-30 bytes (must be even)

// CHECK: sld.hu 0[ep], r10 ; encoding: [0x70,0x50]
sld.hu 0, r10

// CHECK: sld.hu 4[ep], r15 ; encoding: [0x72,0x78]
sld.hu 4, r15

// CHECK: sld.hu 30[ep], r20 ; encoding: [0x7f,0xa0]
sld.hu 30, r20
