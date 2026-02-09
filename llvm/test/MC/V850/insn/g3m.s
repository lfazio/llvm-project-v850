// RUN: llvm-mc -triple=v850-unknown-elf -mcpu=g3m -show-encoding < %s | FileCheck %s
// RUN: llvm-mc -triple=v850-unknown-elf -mcpu=g3mh -show-encoding < %s | FileCheck %s

// Test RH850G3M specific instructions

// SYNCI - Synchronize instruction pipeline
// CHECK: synci ; encoding: [0x1c,0x00]
	synci

// SNOOZE - Enter low-power snooze state
// CHECK: snooze ; encoding: [0xe0,0x0f,0x20,0x01]
	snooze

// CLL - Clear load link state
// CHECK: cll ; encoding: [0xff,0xff,0x60,0xf1]
	cll

// LDL.W - Load linked word
// CHECK: ldl.w [r10], r11 ; encoding: [0xea,0x07,0x78,0x5b]
	ldl.w [r10], r11

// CHECK: ldl.w [r0], r1 ; encoding: [0xe0,0x07,0x78,0x0b]
	ldl.w [r0], r1

// CHECK: ldl.w [r31], r31 ; encoding: [0xff,0x07,0x78,0xfb]
	ldl.w [r31], r31

// STC.W - Store conditional word
// CHECK: stc.w r11, [r10] ; encoding: [0xea,0x07,0x7a,0x5b]
	stc.w r11, [r10]

// CHECK: stc.w r1, [r0] ; encoding: [0xe0,0x07,0x7a,0x0b]
	stc.w r1, [r0]

// CHECK: stc.w r31, [r31] ; encoding: [0xff,0x07,0x7a,0xfb]
	stc.w r31, [r31]

// ROTL - Rotate left with immediate
// CHECK: rotl 5, r6, r10 ; encoding: [0xe5,0x37,0xc4,0x50]
	rotl 5, r6, r10

// CHECK: rotl 0, r0, r0 ; encoding: [0xe0,0x07,0xc4,0x00]
	rotl 0, r0, r0

// CHECK: rotl 31, r31, r31 ; encoding: [0xff,0xff,0xc4,0xf8]
	rotl 31, r31, r31

// ROTL - Rotate left with register
// CHECK: rotl r7, r6, r10 ; encoding: [0xe7,0x37,0xc6,0x50]
	rotl r7, r6, r10

// CHECK: rotl r0, r0, r0 ; encoding: [0xe0,0x07,0xc6,0x00]
	rotl r0, r0, r0

// CHECK: rotl r31, r31, r31 ; encoding: [0xff,0xff,0xc6,0xf8]
	rotl r31, r31, r31
