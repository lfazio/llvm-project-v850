// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// Test basic assembly parsing and encoding

// Format I - Register-Register instructions
// CHECK: nop                      # encoding: [0x00,0x00]
nop

// CHECK: add gr1, gr2             # encoding: [0xc1,0x11]
add gr1, gr2

// CHECK: sub gr3, gr4             # encoding: [0xa3,0x21]
sub gr3, gr4

// CHECK: mov gr5, gr6             # encoding: [0x05,0x30]
mov gr5, gr6

// CHECK: not gr7, gr8             # encoding: [0x27,0x40]
not gr7, gr8

// CHECK: or gr9, gr10             # encoding: [0x09,0x51]
or gr9, gr10

// CHECK: and gr11, gr12           # encoding: [0x4b,0x61]
and gr11, gr12

// CHECK: xor gr13, gr14           # encoding: [0x2d,0x71]
xor gr13, gr14
