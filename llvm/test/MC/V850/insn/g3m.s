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

// PUSHSP - Push registers to stack
// CHECK: pushsp r20, r31 ; encoding: [0xf4,0x47,0x60,0xf9]
	pushsp r20, r31

// CHECK: pushsp r0, r0 ; encoding: [0xe0,0x47,0x60,0x01]
	pushsp r0, r0

// POPSP - Pop registers from stack
// CHECK: popsp r20, r31 ; encoding: [0xf4,0x67,0x60,0xf9]
	popsp r20, r31

// CHECK: popsp r0, r0 ; encoding: [0xe0,0x67,0x60,0x01]
	popsp r0, r0

// LOOP - Hardware loop
// CHECK: loop r5, -100 ; encoding: [0xe5,0x06,0xcf,0xff]
	loop r5, -100

// CHECK: loop r10, -2 ; encoding: [0xea,0x06,0xff,0xff]
	loop r10, -2

// CACHE - Cache operation (7-bit cacheop: bits 6-5 in inst[12-11], bits 4-0 in inst[31-27])
// CHECK: cache 0, [r10] ; encoding: [0xea,0xe7,0x60,0x01]
	cache 0, [r10]

// CHECK: cache 31, [r5] ; encoding: [0xe5,0xe7,0x60,0xf9]
	cache 31, [r5]

// CHECK: cache 127, [r5] ; encoding: [0xe5,0xff,0x60,0xf9]
	cache 127, [r5]

// PREF - Prefetch
// CHECK: pref 0, [r10] ; encoding: [0xea,0xdf,0x60,0x01]
	pref 0, [r10]

// BINS - Bitfield insert
// Note: BINS encodes 4 bits of lsb and msb. The assembler always uses variant 0.
// CHECK: bins r6, 0, 15, r10 ; encoding: [0xe6,0x57,0x90,0xf0]
	bins r6, 0, 15, r10

// CHECK: bins r0, 0, 0, r0 ; encoding: [0xe0,0x07,0x90,0x00]
	bins r0, 0, 0, r0

// LD.DW - Load doubleword (48-bit instruction)
// CHECK: ld.dw 100[r10], r12 ; encoding: [0xaa,0x07,0x49,0x66,0x00,0x00]
	ld.dw 100[r10], r12

// CHECK: ld.dw 0[r0], r0 ; encoding: [0xa0,0x07,0x09,0x00,0x00,0x00]
	ld.dw 0[r0], r0

// ST.DW - Store doubleword (48-bit instruction)
// CHECK: st.dw r14, 200[r10] ; encoding: [0xaa,0x07,0x8f,0x74,0x01,0x00]
	st.dw r14, 200[r10]

// CHECK: st.dw r0, 0[r0] ; encoding: [0xa0,0x07,0x0f,0x00,0x00,0x00]
	st.dw r0, 0[r0]
