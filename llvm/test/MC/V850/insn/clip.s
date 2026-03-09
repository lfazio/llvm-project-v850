// RUN: llvm-mc -triple=v850-unknown-elf -mcpu=g4mh -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850-unknown-elf -mcpu=g4mh2 -show-encoding %s | FileCheck %s

// CLIP instructions - Value saturation (RH850G4MH+)
// Format XI: reg2_111111_reg1 | 00000_000000_subid

// CLIP.B - Clamp signed value to byte range [-128, 127]
// CHECK: clip.b r6, r10 ; encoding: [0xe6,0x57,0x08,0x00]
clip.b r6, r10

// CHECK: clip.b r1, r31 ; encoding: [0xe1,0xff,0x08,0x00]
clip.b r1, r31

// CHECK: clip.b r31, r1 ; encoding: [0xff,0x0f,0x08,0x00]
clip.b r31, r1

// CLIP.BU - Clamp value to unsigned byte range [0, 255]
// CHECK: clip.bu r6, r10 ; encoding: [0xe6,0x57,0x0a,0x00]
clip.bu r6, r10

// CHECK: clip.bu r1, r31 ; encoding: [0xe1,0xff,0x0a,0x00]
clip.bu r1, r31

// CLIP.H - Clamp signed value to halfword range [-32768, 32767]
// CHECK: clip.h r6, r10 ; encoding: [0xe6,0x57,0x0c,0x00]
clip.h r6, r10

// CHECK: clip.h r1, r31 ; encoding: [0xe1,0xff,0x0c,0x00]
clip.h r1, r31

// CLIP.HU - Clamp value to unsigned halfword range [0, 65535]
// CHECK: clip.hu r6, r10 ; encoding: [0xe6,0x57,0x0e,0x00]
clip.hu r6, r10

// CHECK: clip.hu r1, r31 ; encoding: [0xe1,0xff,0x0e,0x00]
clip.hu r1, r31
