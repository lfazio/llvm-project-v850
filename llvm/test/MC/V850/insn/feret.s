// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// FERET - Return from FE Level Exception (32-bit)
// Restores PC and PSW from FEPC and FEPSW
// Requires: V850E2M or later

// CHECK: feret ; encoding: [0xe0,0x07,0x4a,0x01]
feret
