// RUN: llvm-mc -triple=v850 -mcpu=v850e1 %s -show-encoding | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2m %s -show-encoding | FileCheck %s

// Test that V850E1+ system registers work on V850E1 and later

// CTPC (regID 16)
// CHECK: stsr ctpc, r10 ; encoding: [0xf0,0x57,0x80,0x04]
stsr ctpc, r10

// CHECK: ldsr r10, ctpc ; encoding: [0xf0,0x57,0x00,0x04]
ldsr r10, ctpc

// CTPSW (regID 17)
// CHECK: stsr ctpsw, r10 ; encoding: [0xf1,0x57,0x80,0x04]
stsr ctpsw, r10

// CHECK: ldsr r10, ctpsw ; encoding: [0xf1,0x57,0x00,0x04]
ldsr r10, ctpsw

// CTBP (regID 20)
// CHECK: stsr ctbp, r10 ; encoding: [0xf4,0x57,0x80,0x04]
stsr ctbp, r10

// CHECK: ldsr r10, ctbp ; encoding: [0xf4,0x57,0x00,0x04]
ldsr r10, ctbp
