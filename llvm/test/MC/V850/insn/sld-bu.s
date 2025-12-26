// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// SLD.BU - Short load byte unsigned (Format IV-BU, 16-bit)
// Syntax: sld.bu disp4, reg2 (EP is implicit base)
// Operation: reg2 <- zero_extend(mem[EP + disp4])
// Displacement range: 0-15 bytes

// CHECK: sld.bu 0[ep], r10 ; encoding: [0x60,0x50]
sld.bu 0, r10

// CHECK: sld.bu 5[ep], r15 ; encoding: [0x65,0x78]
sld.bu 5, r15

// CHECK: sld.bu 15[ep], r20 ; encoding: [0x6f,0xa0]
sld.bu 15, r20
