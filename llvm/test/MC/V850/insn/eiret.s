// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// EIRET - Return from EI Level Exception (32-bit)
// Restores PC and PSW from EIPC and EIPSW
// Requires: V850E2M or later

// CHECK: eiret ; encoding: [0xe0,0x07,0x48,0x01]
eiret
