// RUN: not llvm-mc -triple=v850 %s 2>&1 | FileCheck %s
// RUN: not llvm-mc -triple=v850 -mcpu=g3mh %s 2>&1 | FileCheck %s
// RUN: not llvm-mc -triple=v850 -mcpu=g4mh %s 2>&1 | FileCheck %s

// Test that RH850G4MH2 virtualization instructions are rejected on pre-G4MH2 CPUs

// CHECK: error: instruction requires a CPU feature not available
hvtrap 0
