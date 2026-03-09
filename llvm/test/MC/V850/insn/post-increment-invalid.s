// RUN: not llvm-mc -triple=v850 %s 2>&1 | FileCheck %s
// RUN: not llvm-mc -triple=v850 -mcpu=g3mh %s 2>&1 | FileCheck %s

// Test that RH850G4MH post-increment instructions are rejected on
// pre-G4MH CPUs

// CHECK: error: instruction requires a CPU feature not available
ld.b [r6]+, r10
