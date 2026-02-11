// RUN: llvm-mc -triple=v850-unknown-elf -mcpu=g3m -show-encoding < %s | FileCheck %s

// Test RH850G3M extended conditional branch instructions (Bcond disp17)
// Format: 00000111111DCCCC ddddddddddddddd1
// D = sign bit of half-displacement, CCCC = condition code
// d = bits 14-0 of half-displacement, bit 0 is fixed at 1
//
// All test values are outside the 9-bit Bcond range [-256, 254] to ensure
// the 17-bit form is selected.

// BV disp17 - Overflow
// CHECK: bv 256 ; encoding: [0xe0,0x07,0x01,0x01]
	bv 256

// CHECK: bv -258 ; encoding: [0xf0,0x07,0xff,0xfe]
	bv -258

// BC disp17 - Carry (also BL)
// CHECK: bc 500 ; encoding: [0xe1,0x07,0xf5,0x01]
	bc 500

// BZ disp17 - Zero (also BE)
// CHECK: bz 1000 ; encoding: [0xe2,0x07,0xe9,0x03]
	bz 1000

// BNH disp17 - Not higher
// CHECK: bnh 2000 ; encoding: [0xe3,0x07,0xd1,0x07]
	bnh 2000

// BN disp17 - Negative
// CHECK: bn -2000 ; encoding: [0xf4,0x07,0x31,0xf8]
	bn -2000

// Note: BR (0b0101) is NOT valid for Bcond disp17

// BLT disp17 - Less than (signed)
// CHECK: blt 4000 ; encoding: [0xe6,0x07,0xa1,0x0f]
	blt 4000

// BLE disp17 - Less or equal (signed)
// CHECK: ble -4000 ; encoding: [0xf7,0x07,0x61,0xf0]
	ble -4000

// BNV disp17 - No overflow
// CHECK: bnv 8000 ; encoding: [0xe8,0x07,0x41,0x1f]
	bnv 8000

// BNC disp17 - No carry (also BNL)
// CHECK: bnc -8000 ; encoding: [0xf9,0x07,0xc1,0xe0]
	bnc -8000

// BNZ disp17 - Not zero (also BNE)
// CHECK: bnz 16000 ; encoding: [0xea,0x07,0x81,0x3e]
	bnz 16000

// BH disp17 - Higher
// CHECK: bh -16000 ; encoding: [0xfb,0x07,0x81,0xc1]
	bh -16000

// BP disp17 - Positive
// CHECK: bp 32000 ; encoding: [0xec,0x07,0x01,0x7d]
	bp 32000

// BSA disp17 - Saturated
// CHECK: bsa -32000 ; encoding: [0xfd,0x07,0x01,0x83]
	bsa -32000

// BGE disp17 - Greater or equal (signed)
// CHECK: bge 65534 ; encoding: [0xee,0x07,0xff,0xff]
	bge 65534

// BGT disp17 - Greater than (signed)
// CHECK: bgt -65536 ; encoding: [0xff,0x07,0x01,0x00]
	bgt -65536
