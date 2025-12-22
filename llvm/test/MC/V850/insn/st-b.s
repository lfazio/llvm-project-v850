// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// ST.B - Store byte (Format VII)
// Syntax: st.b reg2, disp16[reg1]
// Operation: store.byte(disp16 + reg1) <- reg2[7:0]

// CHECK: st.b r5, 0[r10] ; encoding: [0x4a,0x2f,0x00,0x00]
st.b r5, 0[r10]

// CHECK: st.b r20, 100[r15] ; encoding: [0x4f,0xa7,0x64,0x00]
st.b r20, 100[r15]

// CHECK: st.b r31, -1[r0] ; encoding: [0x40,0xff,0xff,0xff]
st.b r31, -1[r0]
