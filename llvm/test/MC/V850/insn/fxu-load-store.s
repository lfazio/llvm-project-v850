// RUN: llvm-mc -triple=v850 -mcpu=g4mh -show-encoding %s | FileCheck %s

// FXU Vector Load/Store Instructions (RH850G4MH)
// All load/store instructions are 48-bit (Format M: D)

// LDV.W - Load single word into element
// CHECK: ldv.w 16[r6], 2, wreg10 ; encoding: [0xa6,0x07,0x5d,0x50,0x10,0x00]
ldv.w 16[r6], 2, wreg10

// LDV.DW - Load double-word
// CHECK: ldv.dw 3, 32[r8], wreg12 ; encoding: [0xa8,0x07,0x7d,0x63,0x20,0x00]
ldv.dw 3, 32[r8], wreg12

// LDV.QW - Load quad-word (full 128-bit vector)
// CHECK: ldv.qw 48[r10], wreg14 ; encoding: [0xaa,0x07,0x9d,0x72,0x30,0x00]
ldv.qw 48[r10], wreg14

// LDVZ.H4 - Load 4 halfwords, zero-extend to 4 words
// CHECK: ldvz.h4 64[r12], wreg16 ; encoding: [0xac,0x07,0xdd,0x83,0x40,0x00]
ldvz.h4 64[r12], wreg16

// STV.W - Store single word from element
// CHECK: stv.w wreg10, 16[r6], 1 ; encoding: [0xa6,0x07,0x3d,0x52,0x10,0x00]
stv.w wreg10, 16[r6], 1

// STV.DW - Store double-word (lower pair)
// CHECK: stv.dw wreg12, 32[r8] ; encoding: [0xa8,0x07,0x9d,0x63,0x20,0x00]
stv.dw wreg12, 32[r8]

// STV.DW - Store double-word (upper pair, imm1=1)
// CHECK: stv.dw wreg12, 32[r8], 1 ; encoding: [0xa8,0x07,0xbd,0x63,0x20,0x00]
stv.dw wreg12, 32[r8], 1

// STV.QW - Store quad-word (full 128-bit vector)
// CHECK: stv.qw wreg14, 48[r10] ; encoding: [0xaa,0x07,0xbd,0x72,0x30,0x00]
stv.qw wreg14, 48[r10]

// STVZ.H4 - Store 4 words truncated to halfwords
// CHECK: stvz.h4 wreg16, 64[r12] ; encoding: [0xac,0x07,0xfd,0x83,0x40,0x00]
stvz.h4 wreg16, 64[r12]
