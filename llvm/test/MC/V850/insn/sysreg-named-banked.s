// RUN: llvm-mc -triple=v850 -mcpu=g3m -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=g3m -filetype=obj %s \
// RUN:     | llvm-objdump -d --mcpu=g3m - \
// RUN:     | FileCheck %s --check-prefix=DISASM

// Test named banked system register syntax for RH850G3M.
// The unified 10-bit encoding: (selID << 5) | regID.
//
// Both named and numeric (regID, selID) syntaxes are accepted.
// Named registers print their name; unnamed encodings print as "regID, selID".

//===----------------------------------------------------------------------===//
// Group 1: Machine Configuration Registers (selID=1)
//===----------------------------------------------------------------------===//

// EBASE - Exception handler vector base (regID=3, selID=1, enc=35)
// CHECK: ldsr r6, ebase ; encoding: [0xe3,0x37,0x01,0x04]
// DISASM: ldsr r6, ebase
ldsr r6, ebase

// CHECK: stsr ebase, r10 ; encoding: [0xe3,0x57,0x81,0x04]
// DISASM: stsr ebase, r10
stsr ebase, r10

// Numeric form: regID=3, selID=1 (same encoding as 'ebase')
// CHECK: ldsr r6, ebase ; encoding: [0xe3,0x37,0x01,0x04]
ldsr r6, 3, 1

// CHECK: stsr ebase, r10 ; encoding: [0xe3,0x57,0x81,0x04]
stsr 3, r10, 1

// INTBP - Interrupt handler table base (regID=4, selID=1, enc=36)
// CHECK: ldsr r7, intbp ; encoding: [0xe4,0x3f,0x01,0x04]
// DISASM: ldsr r7, intbp
ldsr r7, intbp

// CHECK: stsr intbp, r11 ; encoding: [0xe4,0x5f,0x81,0x04]
// DISASM: stsr intbp, r11
stsr intbp, r11

// RBASE - Reset vector base (regID=2, selID=1, enc=34)
// CHECK: ldsr r8, rbase ; encoding: [0xe2,0x47,0x01,0x04]
// DISASM: ldsr r8, rbase
ldsr r8, rbase

// SCBP - SYSCALL base pointer (regID=12, selID=1, enc=44)
// CHECK: ldsr r9, scbp_g1 ; encoding: [0xec,0x4f,0x01,0x04]
// DISASM: ldsr r9, scbp_g1
ldsr r9, scbp_g1

//===----------------------------------------------------------------------===//
// Group 2: Interrupt/Thread Configuration Registers (selID=2)
//===----------------------------------------------------------------------===//

// MEA - Memory error address (regID=6, selID=2, enc=70)
// CHECK: ldsr r6, mea ; encoding: [0xe6,0x37,0x02,0x04]
// DISASM: ldsr r6, mea
ldsr r6, mea

// CHECK: stsr mea, r10 ; encoding: [0xe6,0x57,0x82,0x04]
// DISASM: stsr mea, r10
stsr mea, r10

// MEI - Memory error information (regID=8, selID=2, enc=72)
// CHECK: stsr mei, r12 ; encoding: [0xe8,0x67,0x82,0x04]
// DISASM: stsr mei, r12
stsr mei, r12

// Numeric form for MEI: regID=8, selID=2
// CHECK: stsr mei, r12 ; encoding: [0xe8,0x67,0x82,0x04]
stsr 8, r12, 2

// ISPR - Interrupt priority register (regID=10, selID=2, enc=74)
// CHECK: stsr ispr, r13 ; encoding: [0xea,0x6f,0x82,0x04]
// DISASM: stsr ispr, r13
stsr ispr, r13

// PMR - Priority level mask (regID=11, selID=2, enc=75)
// CHECK: ldsr r14, pmr ; encoding: [0xeb,0x77,0x02,0x04]
// DISASM: ldsr r14, pmr
ldsr r14, pmr

// ICSR - Interrupt control status (regID=12, selID=2, enc=76)
// CHECK: stsr icsr, r15 ; encoding: [0xec,0x7f,0x82,0x04]
// DISASM: stsr icsr, r15
stsr icsr, r15

// INTCFG - Interrupt function setting (regID=13, selID=2, enc=77)
// CHECK: ldsr r16, intcfg ; encoding: [0xed,0x87,0x02,0x04]
// DISASM: ldsr r16, intcfg
ldsr r16, intcfg

// CHECK: stsr intcfg, r17 ; encoding: [0xed,0x8f,0x82,0x04]
// DISASM: stsr intcfg, r17
stsr intcfg, r17
