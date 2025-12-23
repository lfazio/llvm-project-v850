// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// STSR - Store from system register (Format IX)
// Syntax: stsr regID, reg2
// Operation: reg2 <- sysreg[regID]

// CHECK: stsr eipc, r10 ; encoding: [0xe0,0x57,0x80,0x04]
stsr eipc, r10
