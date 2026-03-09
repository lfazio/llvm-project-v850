// RUN: llvm-mc -triple=v850-unknown-elf -mcpu=g4mh -show-encoding %s | FileCheck %s
// RUN: llvm-mc -triple=v850-unknown-elf -mcpu=g4mh2 -show-encoding %s | FileCheck %s

// Post-increment/decrement load/store instructions (RH850G4MH+)
// Format XI-PostInc: dir_111111_reg1 | reg3_011011_subid

//===----------------------------------------------------------------------===//
// Post-increment loads (signed)
//===----------------------------------------------------------------------===//

// LD.B [reg1]+, reg3 — signed byte load, post-increment
// CHECK: ld.b [r6]+, r10 ; encoding: [0xe6,0x17,0x70,0x53]
ld.b [r6]+, r10

// LD.B [reg1]-, reg3 — signed byte load, post-decrement
// CHECK: ld.b [r6]-, r10 ; encoding: [0xe6,0x27,0x70,0x53]
ld.b [r6]-, r10

// LD.H [reg1]+, reg3 — signed halfword load, post-increment
// CHECK: ld.h [r6]+, r10 ; encoding: [0xe6,0x17,0x74,0x53]
ld.h [r6]+, r10

// LD.H [reg1]-, reg3 — signed halfword load, post-decrement
// CHECK: ld.h [r6]-, r10 ; encoding: [0xe6,0x27,0x74,0x53]
ld.h [r6]-, r10

// LD.W [reg1]+, reg3 — word load, post-increment
// CHECK: ld.w [r6]+, r10 ; encoding: [0xe6,0x17,0x78,0x53]
ld.w [r6]+, r10

// LD.W [reg1]-, reg3 — word load, post-decrement
// CHECK: ld.w [r6]-, r10 ; encoding: [0xe6,0x27,0x78,0x53]
ld.w [r6]-, r10

//===----------------------------------------------------------------------===//
// Post-increment loads (unsigned)
//===----------------------------------------------------------------------===//

// LD.BU [reg1]+, reg3 — unsigned byte load, post-increment
// CHECK: ld.bu [r6]+, r10 ; encoding: [0xe6,0x1f,0x70,0x53]
ld.bu [r6]+, r10

// LD.BU [reg1]-, reg3 — unsigned byte load, post-decrement
// CHECK: ld.bu [r6]-, r10 ; encoding: [0xe6,0x2f,0x70,0x53]
ld.bu [r6]-, r10

// LD.HU [reg1]+, reg3 — unsigned halfword load, post-increment
// CHECK: ld.hu [r6]+, r10 ; encoding: [0xe6,0x1f,0x74,0x53]
ld.hu [r6]+, r10

// LD.HU [reg1]-, reg3 — unsigned halfword load, post-decrement
// CHECK: ld.hu [r6]-, r10 ; encoding: [0xe6,0x2f,0x74,0x53]
ld.hu [r6]-, r10

//===----------------------------------------------------------------------===//
// Post-increment stores
//===----------------------------------------------------------------------===//

// ST.B reg3, [reg1]+ — byte store, post-increment
// CHECK: st.b r10, [r6]+ ; encoding: [0xe6,0x17,0x72,0x53]
st.b r10, [r6]+

// ST.B reg3, [reg1]- — byte store, post-decrement
// CHECK: st.b r10, [r6]- ; encoding: [0xe6,0x27,0x72,0x53]
st.b r10, [r6]-

// ST.H reg3, [reg1]+ — halfword store, post-increment
// CHECK: st.h r10, [r6]+ ; encoding: [0xe6,0x17,0x76,0x53]
st.h r10, [r6]+

// ST.H reg3, [reg1]- — halfword store, post-decrement
// CHECK: st.h r10, [r6]- ; encoding: [0xe6,0x27,0x76,0x53]
st.h r10, [r6]-

// ST.W reg3, [reg1]+ — word store, post-increment
// CHECK: st.w r10, [r6]+ ; encoding: [0xe6,0x17,0x7a,0x53]
st.w r10, [r6]+

// ST.W reg3, [reg1]- — word store, post-decrement
// CHECK: st.w r10, [r6]- ; encoding: [0xe6,0x27,0x7a,0x53]
st.w r10, [r6]-

//===----------------------------------------------------------------------===//
// Additional register combinations
//===----------------------------------------------------------------------===//

// Test with r1 and r31
// CHECK: ld.w [r1]+, r31 ; encoding: [0xe1,0x17,0x78,0xfb]
ld.w [r1]+, r31

// CHECK: st.w r31, [r1]- ; encoding: [0xe1,0x27,0x7a,0xfb]
st.w r31, [r1]-

// Test with r31 and r1
// CHECK: ld.b [r31]+, r1 ; encoding: [0xff,0x17,0x70,0x0b]
ld.b [r31]+, r1

// CHECK: st.b r1, [r31]- ; encoding: [0xff,0x27,0x72,0x0b]
st.b r1, [r31]-
