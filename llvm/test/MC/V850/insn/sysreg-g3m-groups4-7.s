// RUN: llvm-mc -triple=v850 -mcpu=g3m -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=g3m -filetype=obj %s \
// RUN:     | llvm-objdump -d --mcpu=g3m - \
// RUN:     | FileCheck %s --check-prefix=DISASM

// Test RH850G3M system registers: Groups 4 (cache), 5 (MPU mode), 6-7 (MPU
// regions 0-15), and ASID at its G3M location (Group 2, selID=2).

//===----------------------------------------------------------------------===//
// Group 4 (selID=4) - Instruction Cache Control Registers
// Encoding = (4 << 5) | regID; hardware cache must be installed.
//===----------------------------------------------------------------------===//

// CHECK: ldsr r10, ictagl ; encoding: [0xf0,0x57,0x04,0x04]
// DISASM: ldsr r10, ictagl
ldsr r10, ictagl

// CHECK: ldsr r10, ictagh ; encoding: [0xf1,0x57,0x04,0x04]
// DISASM: ldsr r10, ictagh
ldsr r10, ictagh

// CHECK: ldsr r10, icdatl ; encoding: [0xf2,0x57,0x04,0x04]
// DISASM: ldsr r10, icdatl
ldsr r10, icdatl

// CHECK: ldsr r10, icdath ; encoding: [0xf3,0x57,0x04,0x04]
// DISASM: ldsr r10, icdath
ldsr r10, icdath

// CHECK: ldsr r10, icctrl ; encoding: [0xf8,0x57,0x04,0x04]
// DISASM: ldsr r10, icctrl
ldsr r10, icctrl

// CHECK: stsr iccfg, r6 ; encoding: [0xfa,0x37,0x84,0x04]
// DISASM: stsr iccfg, r6
stsr iccfg, r6

// CHECK: ldsr r10, icerr ; encoding: [0xfc,0x57,0x04,0x04]
// DISASM: ldsr r10, icerr
ldsr r10, icerr

//===----------------------------------------------------------------------===//
// Group 5 (selID=5) - MPU Mode/Control Registers
// Encoding = (5 << 5) | regID; hardware MPU must be installed.
//===----------------------------------------------------------------------===//

// CHECK: ldsr r10, mpm ; encoding: [0xe0,0x57,0x05,0x04]
// DISASM: ldsr r10, mpm
ldsr r10, mpm

// CHECK: ldsr r10, mprc ; encoding: [0xe1,0x57,0x05,0x04]
// DISASM: ldsr r10, mprc
ldsr r10, mprc

// CHECK: stsr mpbrgn, r6 ; encoding: [0xe4,0x37,0x85,0x04]
// DISASM: stsr mpbrgn, r6
stsr mpbrgn, r6

// CHECK: stsr mptrgn, r6 ; encoding: [0xe5,0x37,0x85,0x04]
// DISASM: stsr mptrgn, r6
stsr mptrgn, r6

// CHECK: ldsr r10, mca ; encoding: [0xe8,0x57,0x05,0x04]
// DISASM: ldsr r10, mca
ldsr r10, mca

// CHECK: ldsr r10, mcs ; encoding: [0xe9,0x57,0x05,0x04]
// DISASM: ldsr r10, mcs
ldsr r10, mcs

// CHECK: ldsr r10, mcc ; encoding: [0xea,0x57,0x05,0x04]
// DISASM: ldsr r10, mcc
ldsr r10, mcc

// CHECK: stsr mcr, r10 ; encoding: [0xeb,0x57,0x85,0x04]
// DISASM: stsr mcr, r10
stsr mcr, r10

//===----------------------------------------------------------------------===//
// Group 6 (selID=6) - MPU Protection Area Registers, Regions 0-7
// Encoding = (6 << 5) | regID
// Each region n has: mpla<n> (min addr), mpua<n> (max addr), mpat<n> (attrs)
// Region n registers: mpla<n>=regID(4n), mpua<n>=regID(4n+1), mpat<n>=regID(4n+2)
//===----------------------------------------------------------------------===//

// CHECK: ldsr r10, mpla0 ; encoding: [0xe0,0x57,0x06,0x04]
// DISASM: ldsr r10, mpla0
ldsr r10, mpla0

// CHECK: ldsr r10, mpua0 ; encoding: [0xe1,0x57,0x06,0x04]
// DISASM: ldsr r10, mpua0
ldsr r10, mpua0

// CHECK: ldsr r10, mpat0 ; encoding: [0xe2,0x57,0x06,0x04]
// DISASM: ldsr r10, mpat0
ldsr r10, mpat0

// CHECK: ldsr r10, mpla4 ; encoding: [0xf0,0x57,0x06,0x04]
// DISASM: ldsr r10, mpla4
ldsr r10, mpla4

// CHECK: ldsr r10, mpua7 ; encoding: [0xfd,0x57,0x06,0x04]
// DISASM: ldsr r10, mpua7
ldsr r10, mpua7

// CHECK: ldsr r10, mpat7 ; encoding: [0xfe,0x57,0x06,0x04]
// DISASM: ldsr r10, mpat7
ldsr r10, mpat7

//===----------------------------------------------------------------------===//
// Group 7 (selID=7) - MPU Protection Area Registers, Regions 8-15
// Encoding = (7 << 5) | regID
//===----------------------------------------------------------------------===//

// CHECK: ldsr r10, mpla8 ; encoding: [0xe0,0x57,0x07,0x04]
// DISASM: ldsr r10, mpla8
ldsr r10, mpla8

// CHECK: ldsr r10, mpua8 ; encoding: [0xe1,0x57,0x07,0x04]
// DISASM: ldsr r10, mpua8
ldsr r10, mpua8

// CHECK: ldsr r10, mpat8 ; encoding: [0xe2,0x57,0x07,0x04]
// DISASM: ldsr r10, mpat8
ldsr r10, mpat8

// CHECK: ldsr r10, mpla15 ; encoding: [0xfc,0x57,0x07,0x04]
// DISASM: ldsr r10, mpla15
ldsr r10, mpla15

// CHECK: ldsr r10, mpua15 ; encoding: [0xfd,0x57,0x07,0x04]
// DISASM: ldsr r10, mpua15
ldsr r10, mpua15

// CHECK: ldsr r10, mpat15 ; encoding: [0xfe,0x57,0x07,0x04]
// DISASM: ldsr r10, mpat15
ldsr r10, mpat15

//===----------------------------------------------------------------------===//
// Group 2 (selID=2) - ASID at G3M location (regID=7)
// On G3M, ASID moved from V850E1 location (regID=23, selID=0) to (regID=7,
// selID=2). Use "asid_g2" to access it on G3M targets.
//===----------------------------------------------------------------------===//

// CHECK: stsr asid_g2, r10 ; encoding: [0xe7,0x57,0x82,0x04]
// DISASM: stsr asid_g2, r10
stsr asid_g2, r10

// CHECK: ldsr r6, asid_g2 ; encoding: [0xe7,0x37,0x02,0x04]
// DISASM: ldsr r6, asid_g2
ldsr r6, asid_g2

//===----------------------------------------------------------------------===//
// Numeric form: raw "regID, selID" syntax also works for all new registers
//===----------------------------------------------------------------------===//

// Numeric selID=4 maps to named cache registers
// CHECK: ldsr r10, icctrl ; encoding: [0xf8,0x57,0x04,0x04]
ldsr r10, 24, 4

// Numeric selID=5 maps to named MPU control registers
// CHECK: ldsr r10, mpm ; encoding: [0xe0,0x57,0x05,0x04]
ldsr r10, 0, 5

// Numeric selID=6 maps to named MPU region 0-7 registers
// CHECK: ldsr r10, mpla0 ; encoding: [0xe0,0x57,0x06,0x04]
ldsr r10, 0, 6

// Numeric selID=7 maps to named MPU region 8-15 registers
// CHECK: ldsr r10, mpat15 ; encoding: [0xfe,0x57,0x07,0x04]
ldsr r10, 30, 7
