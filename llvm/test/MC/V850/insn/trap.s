// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// TRAP - Software trap (Format X)
// Syntax: trap vector
// Operation: Generate software exception

// CHECK: trap 0 ; encoding: [0xe0,0x07,0x00,0x02]
trap 0
