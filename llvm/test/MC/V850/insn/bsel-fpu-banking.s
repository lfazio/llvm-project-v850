// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

//===----------------------------------------------------------------------===//
// V850E2M BSEL-based FPU Register Banking Test
//
// This test verifies the complete BSEL banking sequence for FPU register access.
// On V850E2M, FPU system registers (regID 6-11) are only accessible when
// BSEL=0x2000 (FPU Status Bank).
//
// Complete sequence for accessing FPU registers:
//   1. movhi 0x20, r0, rX   ; rX = 0x2000 (FPU bank selector)
//   2. ldsr  rX, bsel       ; Select FPU bank
//   3. stsr/ldsr fpu_reg    ; Read/write FPU register
//   4. mov   r0, rX         ; rX = 0
//   5. ldsr  rX, bsel       ; Restore CPU main bank
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// BSEL Register - Bank Selection
//===----------------------------------------------------------------------===//

// Write BSEL to select FPU bank (0x2000)
// CHECK: movhi 32, r0, r10 ; encoding: [0x40,0x56,0x20,0x00]
movhi 0x20, r0, r10

// CHECK: ldsr r10, bsel ; encoding: [0xff,0x57,0x00,0x04]
ldsr r10, bsel

// Read current BSEL value
// CHECK: stsr bsel, r11 ; encoding: [0xff,0x5f,0x80,0x04]
stsr bsel, r11

// Clear BSEL to restore CPU main bank
// CHECK: mov r0, r10 ; encoding: [0x00,0x50]
mov r0, r10

// CHECK: ldsr r10, bsel ; encoding: [0xff,0x57,0x00,0x04]
ldsr r10, bsel

//===----------------------------------------------------------------------===//
// Complete FPU Register Access Sequences
// Each sequence demonstrates the full BSEL banking pattern
//===----------------------------------------------------------------------===//

// --- Read FPSR (regID 6) ---
// Step 1: Select FPU bank
// CHECK: movhi 32, r0, r12 ; encoding: [0x40,0x66,0x20,0x00]
movhi 0x20, r0, r12
// CHECK: ldsr r12, bsel ; encoding: [0xff,0x67,0x00,0x04]
ldsr r12, bsel
// Step 2: Read FPSR
// CHECK: stsr fpsr, r13 ; encoding: [0xe6,0x6f,0x80,0x04]
stsr fpsr, r13
// Step 3: Restore CPU main bank
// CHECK: mov r0, r12 ; encoding: [0x00,0x60]
mov r0, r12
// CHECK: ldsr r12, bsel ; encoding: [0xff,0x67,0x00,0x04]
ldsr r12, bsel

// --- Write FPCFG (regID 10) ---
// Step 1: Select FPU bank
// CHECK: movhi 32, r0, r14 ; encoding: [0x40,0x76,0x20,0x00]
movhi 0x20, r0, r14
// CHECK: ldsr r14, bsel ; encoding: [0xff,0x77,0x00,0x04]
ldsr r14, bsel
// Step 2: Write FPCFG
// CHECK: ldsr r15, fpcfg ; encoding: [0xea,0x7f,0x00,0x04]
ldsr r15, fpcfg
// Step 3: Restore CPU main bank
// CHECK: mov r0, r14 ; encoding: [0x00,0x70]
mov r0, r14
// CHECK: ldsr r14, bsel ; encoding: [0xff,0x77,0x00,0x04]
ldsr r14, bsel

//===----------------------------------------------------------------------===//
// All FPU System Registers (regID 6-11) in FPU Bank
//===----------------------------------------------------------------------===//

// Assume BSEL is already set to 0x2000 for these tests

// FPSR - Floating-point configuration/status (regID 6)
// CHECK: ldsr r16, fpsr ; encoding: [0xe6,0x87,0x00,0x04]
ldsr r16, fpsr
// CHECK: stsr fpsr, r16 ; encoding: [0xe6,0x87,0x80,0x04]
stsr fpsr, r16

// FPEPC - Floating-point exception PC (regID 7)
// CHECK: ldsr r17, fpepc ; encoding: [0xe7,0x8f,0x00,0x04]
ldsr r17, fpepc
// CHECK: stsr fpepc, r17 ; encoding: [0xe7,0x8f,0x80,0x04]
stsr fpepc, r17

// FPST - Floating-point status (regID 8)
// CHECK: ldsr r18, fpst ; encoding: [0xe8,0x97,0x00,0x04]
ldsr r18, fpst
// CHECK: stsr fpst, r18 ; encoding: [0xe8,0x97,0x80,0x04]
stsr fpst, r18

// FPCC - Floating-point comparison result (regID 9)
// CHECK: ldsr r19, fpcc ; encoding: [0xe9,0x9f,0x00,0x04]
ldsr r19, fpcc
// CHECK: stsr fpcc, r19 ; encoding: [0xe9,0x9f,0x80,0x04]
stsr fpcc, r19

// FPCFG - Floating-point configuration (regID 10)
// CHECK: ldsr r20, fpcfg ; encoding: [0xea,0xa7,0x00,0x04]
ldsr r20, fpcfg
// CHECK: stsr fpcfg, r20 ; encoding: [0xea,0xa7,0x80,0x04]
stsr fpcfg, r20

// FPEC - Floating-point exception control (regID 11)
// On v850e2m, regID 11 prints as 'sccfg' (CPU main bank is default)
// CHECK: ldsr r21, sccfg ; encoding: [0xeb,0xaf,0x00,0x04]
ldsr r21, fpec
// CHECK: stsr sccfg, r21 ; encoding: [0xeb,0xaf,0x80,0x04]
stsr fpec, r21

//===----------------------------------------------------------------------===//
// CPU Main Bank Registers (BSEL=0x0000)
// These are accessible without bank switching
//===----------------------------------------------------------------------===//

// SCCFG - SYSCALL config (regID 11 in CPU Main Bank)
// Note: Same regID as FPEC, but in different bank
// CHECK: ldsr r22, sccfg ; encoding: [0xeb,0xb7,0x00,0x04]
ldsr r22, sccfg
// CHECK: stsr sccfg, r22 ; encoding: [0xeb,0xb7,0x80,0x04]
stsr sccfg, r22

// PSW - Program Status Word (regID 5)
// CHECK: ldsr r23, psw ; encoding: [0xe5,0xbf,0x00,0x04]
ldsr r23, psw
// CHECK: stsr psw, r23 ; encoding: [0xe5,0xbf,0x80,0x04]
stsr psw, r23

//===----------------------------------------------------------------------===//
// BSEL Bank Values Reference
//===----------------------------------------------------------------------===//
// BSEL=0x0000: CPU Main Bank (default)
// BSEL=0x0010: Exception Handler Switching Bank 0
// BSEL=0x0011: Exception Handler Switching Bank 1
// BSEL=0x1000: Processor Protection Violation Bank
// BSEL=0x1010: Software Paging Bank
// BSEL=0x2000: FPU Status Bank
// BSEL=0xFF00: User Bank 0
// BSEL=0xFFFF: User Compatible Bank
