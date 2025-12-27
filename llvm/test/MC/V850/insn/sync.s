// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// SYNCE - Synchronize exceptions (16-bit)
// Waits for all preceding exceptions to be acknowledged
// Requires: V850E2M or later

// CHECK: synce ; encoding: [0x1d,0x00]
synce

// SYNCM - Synchronize memory (16-bit)
// Waits for all preceding memory accesses to complete

// CHECK: syncm ; encoding: [0x1e,0x00]
syncm

// SYNCP - Synchronize pipeline (16-bit)
// Waits for all preceding instructions to complete execution

// CHECK: syncp ; encoding: [0x1f,0x00]
syncp
