// RUN: not llvm-mc -triple=v850 -mcpu=g3mh %s 2>&1 | FileCheck %s

// FXU instructions require RH850G4MH - should fail on G3MH

// CHECK: error: instruction requires a CPU feature not available
absf.s4 wreg4, wreg8

// CHECK: error: instruction requires a CPU feature not available
addf.s4 wreg2, wreg4, wreg6

// CHECK: error: instruction requires a CPU feature not available
fmaf.s4 wreg1, wreg2, wreg3

// CHECK: error: instruction requires a CPU feature not available
ldv.qw 0[r6], wreg10
