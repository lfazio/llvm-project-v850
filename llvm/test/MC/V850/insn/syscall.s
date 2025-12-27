// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// SYSCALL - System Call (32-bit)
// Calls OS system service via table lookup
// vector8 is an 8-bit unsigned immediate (0-255)
// Requires: V850E2M or later

// CHECK: syscall 0 ; encoding: [0xe0,0xd7,0xb0,0x00]
syscall 0

// CHECK: syscall 1 ; encoding: [0xe1,0xd7,0xb0,0x00]
syscall 1

// CHECK: syscall 31 ; encoding: [0xff,0xd7,0xb0,0x00]
syscall 31

// CHECK: syscall 32 ; encoding: [0xe0,0xd7,0xb0,0x04]
syscall 32

// CHECK: syscall 127 ; encoding: [0xff,0xd7,0xb0,0x0c]
syscall 127

// CHECK: syscall 128 ; encoding: [0xe0,0xd7,0xb0,0x10]
syscall 128

// CHECK: syscall 255 ; encoding: [0xff,0xd7,0xb0,0x1c]
syscall 255
