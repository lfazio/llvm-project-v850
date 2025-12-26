// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e1 -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850 -mcpu=v850e2 -show-encoding %s | FileCheck %s

// Test basic assembly parsing and encoding

// Format I - Register-Register instructions
// CHECK: nop                      ; encoding: [0x00,0x00]
nop

// CHECK: add r1, r2             ; encoding: [0xc1,0x11]
add r1, r2

// CHECK: sub r3, r4             ; encoding: [0xa3,0x21]
sub r3, r4

// CHECK: mov r5, r6             ; encoding: [0x05,0x30]
mov r5, r6

// CHECK: not r7, r8             ; encoding: [0x27,0x40]
not r7, r8

// CHECK: or r9, r10             ; encoding: [0x09,0x51]
or r9, r10

// CHECK: and r11, r12           ; encoding: [0x4b,0x61]
and r11, r12

// CHECK: xor r13, r14           ; encoding: [0x2d,0x71]
xor r13, r14
