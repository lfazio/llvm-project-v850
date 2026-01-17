// RUN: llvm-mc -triple=v850 %s -show-encoding | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e1 %s -show-encoding | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2m %s -show-encoding | FileCheck %s

// Test that base V850 system registers work on all CPU variants

// EIPC (regID 0)
// CHECK: stsr eipc, r10 ; encoding: [0xe0,0x57,0x80,0x04]
stsr eipc, r10

// CHECK: ldsr r10, eipc ; encoding: [0xe0,0x57,0x00,0x04]
ldsr r10, eipc

// PSW (regID 5)
// CHECK: stsr psw, r5 ; encoding: [0xe5,0x2f,0x80,0x04]
stsr psw, r5

// CHECK: ldsr r5, psw ; encoding: [0xe5,0x2f,0x00,0x04]
ldsr r5, psw
