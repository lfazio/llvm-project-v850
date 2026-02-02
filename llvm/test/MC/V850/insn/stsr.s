// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// STSR - Store from system register (Format IX)
// Syntax: stsr regID, reg2
// Operation: reg2 <- sysreg[regID]
// Note: Tests use v850e2m to include all system register variants

//===----------------------------------------------------------------------===//
// Base V850 System Registers (All variants)
//===----------------------------------------------------------------------===//

// CHECK: stsr eipc, r10 ; encoding: [0xe0,0x57,0x80,0x04]
stsr eipc, r10

// CHECK: stsr eipsw, r11 ; encoding: [0xe1,0x5f,0x80,0x04]
stsr eipsw, r11

// CHECK: stsr fepc, r12 ; encoding: [0xe2,0x67,0x80,0x04]
stsr fepc, r12

// CHECK: stsr fepsw, r13 ; encoding: [0xe3,0x6f,0x80,0x04]
stsr fepsw, r13

// CHECK: stsr ecr, r14 ; encoding: [0xe4,0x77,0x80,0x04]
stsr ecr, r14

// CHECK: stsr psw, r15 ; encoding: [0xe5,0x7f,0x80,0x04]
stsr psw, r15

//===----------------------------------------------------------------------===//
// V850E1 Additional System Registers
//===----------------------------------------------------------------------===//

// CHECK: stsr ctpc, r16 ; encoding: [0xf0,0x87,0x80,0x04]
stsr ctpc, r16

// CHECK: stsr ctpsw, r17 ; encoding: [0xf1,0x8f,0x80,0x04]
stsr ctpsw, r17

// CHECK: stsr dbpc, r18 ; encoding: [0xf2,0x97,0x80,0x04]
stsr dbpc, r18

// CHECK: stsr dbpsw, r19 ; encoding: [0xf3,0x9f,0x80,0x04]
stsr dbpsw, r19

// CHECK: stsr ctbp, r20 ; encoding: [0xf4,0xa7,0x80,0x04]
stsr ctbp, r20

// CHECK: stsr dir, r21 ; encoding: [0xf5,0xaf,0x80,0x04]
stsr dir, r21

// CHECK: stsr bpc, r22 ; encoding: [0xf6,0xb7,0x80,0x04]
stsr bpc, r22

// CHECK: stsr asid, r23 ; encoding: [0xf7,0xbf,0x80,0x04]
stsr asid, r23

// CHECK: stsr bpav, r24 ; encoding: [0xf8,0xc7,0x80,0x04]
stsr bpav, r24

// CHECK: stsr bpam, r25 ; encoding: [0xf9,0xcf,0x80,0x04]
stsr bpam, r25

// CHECK: stsr bpdv, r26 ; encoding: [0xfa,0xd7,0x80,0x04]
stsr bpdv, r26

// CHECK: stsr bpdm, r27 ; encoding: [0xfb,0xdf,0x80,0x04]
stsr bpdm, r27

//===----------------------------------------------------------------------===//
// V850E2M FPU System Registers
//===----------------------------------------------------------------------===//

// CHECK: stsr fpsr, r6 ; encoding: [0xe6,0x37,0x80,0x04]
stsr fpsr, r6

// CHECK: stsr fpepc, r7 ; encoding: [0xe7,0x3f,0x80,0x04]
stsr fpepc, r7

// CHECK: stsr fpst, r8 ; encoding: [0xe8,0x47,0x80,0x04]
stsr fpst, r8

// CHECK: stsr fpcc, r9 ; encoding: [0xe9,0x4f,0x80,0x04]
stsr fpcc, r9

// CHECK: stsr fpcfg, r10 ; encoding: [0xea,0x57,0x80,0x04]
stsr fpcfg, r10

// CHECK: stsr fpec, r11 ; encoding: [0xeb,0x5f,0x80,0x04]
stsr fpec, r11

//===----------------------------------------------------------------------===//
// V850E2M SYSCALL and Exception Registers
//===----------------------------------------------------------------------===//

// CHECK: stsr sccfg, r12 ; encoding: [0xeb,0x67,0x80,0x04]
stsr sccfg, r12

// CHECK: stsr scbp, r13 ; encoding: [0xec,0x6f,0x80,0x04]
stsr scbp, r13

// CHECK: stsr eiic, r14 ; encoding: [0xed,0x77,0x80,0x04]
stsr eiic, r14

// CHECK: stsr feic, r15 ; encoding: [0xee,0x7f,0x80,0x04]
stsr feic, r15

// CHECK: stsr dbic, r16 ; encoding: [0xef,0x87,0x80,0x04]
stsr dbic, r16

//===----------------------------------------------------------------------===//
// V850E2M Working and Bank Selection Registers
//===----------------------------------------------------------------------===//

// CHECK: stsr eiwr, r17 ; encoding: [0xfc,0x8f,0x80,0x04]
stsr eiwr, r17

// CHECK: stsr fewr, r18 ; encoding: [0xfd,0x97,0x80,0x04]
stsr fewr, r18

// CHECK: stsr dbwr, r19 ; encoding: [0xfe,0x9f,0x80,0x04]
stsr dbwr, r19

// CHECK: stsr bsel, r20 ; encoding: [0xff,0xa7,0x80,0x04]
stsr bsel, r20
