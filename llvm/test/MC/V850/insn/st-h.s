// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// ST.H - Store halfword (Format VII)
// Syntax: st.h reg2, disp16[reg1]
// Operation: store.halfword(disp16 + reg1) <- reg2[15:0]

// CHECK: st.h r5, 0[r10] ; encoding: [0x6a,0x2f,0x00,0x00]
st.h r5, 0[r10]

// CHECK: st.h r20, 100[r15] ; encoding: [0x6f,0xa7,0x64,0x00]
st.h r20, 100[r15]

// CHECK: st.h r31, -2[r0] ; encoding: [0x60,0xff,0xfe,0xff]
st.h r31, -2[r0]
