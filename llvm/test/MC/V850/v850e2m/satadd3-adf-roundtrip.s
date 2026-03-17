// RUN: llvm-mc -triple=v850 -mcpu=v850e2m --show-encoding %s | FileCheck %s

// Test that SATADD_3/SATSUB_3 and ADF/SBF with cond=C produce identical encodings.
// These are encoding aliases — the same machine instruction with two mnemonics.

// CHECK: satadd	r1, r2, r3              ; encoding: [0xe1,0x17,0xa2,0x1b]
satadd r1, r2, r3

// CHECK: adf	c, r1, r2, r3                   ; encoding: [0xe1,0x17,0xa2,0x1b]
adf c, r1, r2, r3

// CHECK: satsub	r1, r2, r3              ; encoding: [0xe1,0x17,0x82,0x1b]
satsub r1, r2, r3

// CHECK: sbf	c, r1, r2, r3                   ; encoding: [0xe1,0x17,0x82,0x1b]
sbf c, r1, r2, r3
