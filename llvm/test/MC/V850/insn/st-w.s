// RUN: llvm-mc -triple=v850 -show-encoding %s | FileCheck %s

// ST.W - Store word (Format VII)
// Syntax: st.w reg2, disp16[reg1]
// Operation: store.word(disp16 + reg1) <- reg2

// CHECK: st.w r5, 0[r10] ; encoding: [0x6a,0x2f,0x01,0x00]
st.w r5, 0[r10]

// CHECK: st.w r20, 100[r15] ; encoding: [0x6f,0xa7,0x65,0x00]
st.w r20, 100[r15]

// CHECK: st.w r31, -4[r0] ; encoding: [0x60,0xff,0xfd,0xff]
st.w r31, -4[r0]
