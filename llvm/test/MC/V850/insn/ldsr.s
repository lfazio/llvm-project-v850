// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// LDSR - Load to system register (Format IX)
// Syntax: ldsr reg2, regID
// Operation: sysreg[regID] <- reg2

//===----------------------------------------------------------------------===//
// Base V850 System Registers (All variants)
//===----------------------------------------------------------------------===//

// CHECK: ldsr r10, eipc ; encoding: [0xe0,0x57,0x00,0x04]
ldsr r10, eipc

// CHECK: ldsr r11, eipsw ; encoding: [0xe1,0x5f,0x00,0x04]
ldsr r11, eipsw

// CHECK: ldsr r12, fepc ; encoding: [0xe2,0x67,0x00,0x04]
ldsr r12, fepc

// CHECK: ldsr r13, fepsw ; encoding: [0xe3,0x6f,0x00,0x04]
ldsr r13, fepsw

// CHECK: ldsr r14, ecr ; encoding: [0xe4,0x77,0x00,0x04]
ldsr r14, ecr

// CHECK: ldsr r15, psw ; encoding: [0xe5,0x7f,0x00,0x04]
ldsr r15, psw

//===----------------------------------------------------------------------===//
// V850E1 Additional System Registers
//===----------------------------------------------------------------------===//

// CHECK: ldsr r16, ctpc ; encoding: [0xf0,0x87,0x00,0x04]
ldsr r16, ctpc

// CHECK: ldsr r17, ctpsw ; encoding: [0xf1,0x8f,0x00,0x04]
ldsr r17, ctpsw

// CHECK: ldsr r18, dbpc ; encoding: [0xf2,0x97,0x00,0x04]
ldsr r18, dbpc

// CHECK: ldsr r19, dbpsw ; encoding: [0xf3,0x9f,0x00,0x04]
ldsr r19, dbpsw

// CHECK: ldsr r20, ctbp ; encoding: [0xf4,0xa7,0x00,0x04]
ldsr r20, ctbp

// CHECK: ldsr r21, dir ; encoding: [0xf5,0xaf,0x00,0x04]
ldsr r21, dir

// CHECK: ldsr r22, bpc ; encoding: [0xf6,0xb7,0x00,0x04]
ldsr r22, bpc

// CHECK: ldsr r23, asid ; encoding: [0xf7,0xbf,0x00,0x04]
ldsr r23, asid

// CHECK: ldsr r24, bpav ; encoding: [0xf8,0xc7,0x00,0x04]
ldsr r24, bpav

// CHECK: ldsr r25, bpam ; encoding: [0xf9,0xcf,0x00,0x04]
ldsr r25, bpam

// CHECK: ldsr r26, bpdv ; encoding: [0xfa,0xd7,0x00,0x04]
ldsr r26, bpdv

// CHECK: ldsr r27, bpdm ; encoding: [0xfb,0xdf,0x00,0x04]
ldsr r27, bpdm

//===----------------------------------------------------------------------===//
// V850E2M FPU System Registers
//===----------------------------------------------------------------------===//

// CHECK: ldsr r6, fpsr ; encoding: [0xe6,0x37,0x00,0x04]
ldsr r6, fpsr

// CHECK: ldsr r7, fpepc ; encoding: [0xe7,0x3f,0x00,0x04]
ldsr r7, fpepc

// CHECK: ldsr r8, fpst ; encoding: [0xe8,0x47,0x00,0x04]
ldsr r8, fpst

// CHECK: ldsr r9, fpcc ; encoding: [0xe9,0x4f,0x00,0x04]
ldsr r9, fpcc

// CHECK: ldsr r10, fpcfg ; encoding: [0xea,0x57,0x00,0x04]
ldsr r10, fpcfg

// CHECK: ldsr r11, fpec ; encoding: [0xeb,0x5f,0x00,0x04]
ldsr r11, fpec

//===----------------------------------------------------------------------===//
// V850E2M SYSCALL and Exception Registers
//===----------------------------------------------------------------------===//

// CHECK: ldsr r12, sccfg ; encoding: [0xeb,0x67,0x00,0x04]
ldsr r12, sccfg

// CHECK: ldsr r13, scbp ; encoding: [0xec,0x6f,0x00,0x04]
ldsr r13, scbp

// CHECK: ldsr r14, eiic ; encoding: [0xed,0x77,0x00,0x04]
ldsr r14, eiic

// CHECK: ldsr r15, feic ; encoding: [0xee,0x7f,0x00,0x04]
ldsr r15, feic

// CHECK: ldsr r16, dbic ; encoding: [0xef,0x87,0x00,0x04]
ldsr r16, dbic

//===----------------------------------------------------------------------===//
// V850E2M Working and Bank Selection Registers
//===----------------------------------------------------------------------===//

// CHECK: ldsr r17, eiwr ; encoding: [0xfc,0x8f,0x00,0x04]
ldsr r17, eiwr

// CHECK: ldsr r18, fewr ; encoding: [0xfd,0x97,0x00,0x04]
ldsr r18, fewr

// CHECK: ldsr r19, dbwr ; encoding: [0xfe,0x9f,0x00,0x04]
ldsr r19, dbwr

// CHECK: ldsr r20, bsel ; encoding: [0xff,0xa7,0x00,0x04]
ldsr r20, bsel
