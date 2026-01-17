// RUN: llvm-mc -triple=v850 -mcpu=v850e2m %s -show-encoding | FileCheck %s

// Test that V850E2M+ system registers work on V850E2M and later

// EIWR (regID 28)
// CHECK: stsr eiwr, r10 ; encoding: [0xfc,0x57,0x80,0x04]
stsr eiwr, r10

// CHECK: ldsr r10, eiwr ; encoding: [0xfc,0x57,0x00,0x04]
ldsr r10, eiwr

// FEWR (regID 29)
// CHECK: stsr fewr, r10 ; encoding: [0xfd,0x57,0x80,0x04]
stsr fewr, r10

// CHECK: ldsr r10, fewr ; encoding: [0xfd,0x57,0x00,0x04]
ldsr r10, fewr

// BSEL (regID 31)
// CHECK: stsr bsel, r10 ; encoding: [0xff,0x57,0x80,0x04]
stsr bsel, r10

// CHECK: ldsr r10, bsel ; encoding: [0xff,0x57,0x00,0x04]
ldsr r10, bsel
