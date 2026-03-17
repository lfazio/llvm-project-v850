// RUN: llvm-mc -triple=v850 -mcpu=v850e2m --show-encoding %s | FileCheck %s

// Test that SATADD_3/SATSUB_3 and ADF/SBF with cond=SA produce identical encodings.
// SATADD_3 is an alias for ADF with SA (saturated) condition.
// SATSUB_3 is an alias for SBF with SA (saturated) condition.

// CHECK: satadd	r1, r2, r3              ; encoding: [0xe1,0x17,0xba,0x1b]
satadd r1, r2, r3

// CHECK: adf	sa, r1, r2, r3                  ; encoding: [0xe1,0x17,0xba,0x1b]
adf sa, r1, r2, r3

// CHECK: satsub	r1, r2, r3              ; encoding: [0xe1,0x17,0x9a,0x1b]
satsub r1, r2, r3

// CHECK: sbf	sa, r1, r2, r3                  ; encoding: [0xe1,0x17,0x9a,0x1b]
sbf sa, r1, r2, r3

// ADF with other conditions should NOT match SATADD encoding
// CHECK: adf	c, r1, r2, r3                   ; encoding: [0xe1,0x17,0xa2,0x1b]
adf c, r1, r2, r3
