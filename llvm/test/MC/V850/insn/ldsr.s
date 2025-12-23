// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// LDSR - Load to system register (Format IX)
// Syntax: ldsr reg2, regID
// Operation: sysreg[regID] <- reg2

// CHECK: ldsr r10, eipc ; encoding: [0xe0,0x57,0x00,0x04]
ldsr r10, eipc
