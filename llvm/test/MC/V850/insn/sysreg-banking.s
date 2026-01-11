// RUN: llvm-mc -triple=v850 -mcpu=v850e2m -show-encoding %s | FileCheck %s

// Test V850E2M System Register Banking
// This file demonstrates proper FPU register access via BSEL register banking.
//
// V850E2M uses BSEL (SR31) to select register banks:
//   BSEL=0x0000: CPU Main Bank (default)
//   BSEL=0x2000: FPU Status Bank
//
// FPU system registers (regID 6-11) are only accessible when BSEL=0x2000.
// In CPU Main Bank (BSEL=0x0000), regID 6-10 are undefined and regID 11 is SCCFG.

//===----------------------------------------------------------------------===//
// BSEL Register Access
//===----------------------------------------------------------------------===//

// Read current BSEL value
// CHECK: stsr bsel, r10 ; encoding: [0xff,0x57,0x80,0x04]
stsr bsel, r10

// Write BSEL to select FPU bank (0x2000)
// First prepare the value 0x2000 in a register
// CHECK: movhi 32, r0, r11 ; encoding: [0x40,0x5e,0x20,0x00]
movhi 0x20, r0, r11

// CHECK: ldsr r11, bsel ; encoding: [0xff,0x5f,0x00,0x04]
ldsr r11, bsel

//===----------------------------------------------------------------------===//
// FPU System Registers (require BSEL=0x2000)
// Note: These encodings are correct, but accessing without proper BSEL
// setting will result in undefined behavior on real hardware.
//===----------------------------------------------------------------------===//

// FPSR - Floating-point configuration/status (regID 6)
// CHECK: ldsr r12, fpsr ; encoding: [0xe6,0x67,0x00,0x04]
ldsr r12, fpsr

// CHECK: stsr fpsr, r12 ; encoding: [0xe6,0x67,0x80,0x04]
stsr fpsr, r12

// FPEPC - Floating-point exception PC (regID 7)
// CHECK: ldsr r13, fpepc ; encoding: [0xe7,0x6f,0x00,0x04]
ldsr r13, fpepc

// CHECK: stsr fpepc, r13 ; encoding: [0xe7,0x6f,0x80,0x04]
stsr fpepc, r13

// FPST - Floating-point status (regID 8)
// CHECK: ldsr r14, fpst ; encoding: [0xe8,0x77,0x00,0x04]
ldsr r14, fpst

// CHECK: stsr fpst, r14 ; encoding: [0xe8,0x77,0x80,0x04]
stsr fpst, r14

// FPCC - Floating-point comparison result (regID 9)
// CHECK: ldsr r15, fpcc ; encoding: [0xe9,0x7f,0x00,0x04]
ldsr r15, fpcc

// CHECK: stsr fpcc, r15 ; encoding: [0xe9,0x7f,0x80,0x04]
stsr fpcc, r15

// FPCFG - Floating-point configuration (regID 10)
// CHECK: ldsr r16, fpcfg ; encoding: [0xea,0x87,0x00,0x04]
ldsr r16, fpcfg

// CHECK: stsr fpcfg, r16 ; encoding: [0xea,0x87,0x80,0x04]
stsr fpcfg, r16

// FPEC - Floating-point exception control (regID 11 in FPU bank)
// CHECK: ldsr r17, fpec ; encoding: [0xeb,0x8f,0x00,0x04]
ldsr r17, fpec

// CHECK: stsr fpec, r17 ; encoding: [0xeb,0x8f,0x80,0x04]
stsr fpec, r17

//===----------------------------------------------------------------------===//
// Restore CPU Main Bank (BSEL=0x0000)
//===----------------------------------------------------------------------===//

// Clear register and write to BSEL
// CHECK: mov r0, r11 ; encoding: [0x00,0x58]
mov r0, r11

// CHECK: ldsr r11, bsel ; encoding: [0xff,0x5f,0x00,0x04]
ldsr r11, bsel

//===----------------------------------------------------------------------===//
// SCCFG - SYSCALL config (regID 11 in CPU Main Bank)
// Note: Same regID as FPEC, but in different bank.
// This register is accessible in CPU Main Bank (BSEL=0x0000).
//===----------------------------------------------------------------------===//

// CHECK: ldsr r18, sccfg ; encoding: [0xeb,0x97,0x00,0x04]
ldsr r18, sccfg

// CHECK: stsr sccfg, r18 ; encoding: [0xeb,0x97,0x80,0x04]
stsr sccfg, r18

//===----------------------------------------------------------------------===//
// Complete FPU Register Access Example
// Demonstrates the full sequence for reading/writing FPU registers.
//===----------------------------------------------------------------------===//

// Step 1: Save current BSEL value (optional, for restoration)
// stsr bsel, r20

// Step 2: Switch to FPU bank
// movhi 0x20, r0, r21
// ldsr r21, bsel

// Step 3: Access FPU registers
// stsr fpsr, r22        ; Read FPSR
// ... process FPU status ...
// ldsr r23, fpcc        ; Write FPCC

// Step 4: Restore CPU Main Bank
// mov r0, r21
// ldsr r21, bsel
// (or: ldsr r20, bsel if saved)
