// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// RIE - Reserved Instruction Exception (16-bit)
// Triggers a reserved instruction exception
// Requires: V850E2M or later

// CHECK: rie ; encoding: [0x40,0x00]
rie
