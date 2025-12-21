// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// BLE - Branch if less or equal (signed) (Format III)
// Syntax: ble disp9
// Condition: ((S ^ OV) | Z) = 1

// CHECK: ble 0 ; encoding: [0x87,0x05]
ble 0
