// RUN: llvm-mc -triple=v850 -mcpu=v850es -show-encoding %s | FileCheck %s

// Test that V850ES CPU variant is recognized and supports extended instruction set
// V850ES has the same ISA as V850E1 but only 6 base system registers

//===----------------------------------------------------------------------===//
// Test V850E1/ES extended instructions are available
//===----------------------------------------------------------------------===//

// CALLT instruction (V850E1/ES extension)
// CHECK: callt 32 ; encoding: [0x20,0x02]
callt 32

// BSH - Byte swap halfword (V850E1/ES extension)
// CHECK: bsh r10, r12 ; encoding: [0xe0,0x57,0x42,0x63]
bsh r10, r12

// CMOV - Conditional move (V850E1/ES extension)
// CHECK: cmov z, r10, r11, r12 ; encoding: [0xea,0x5f,0x24,0x63]
cmov z, r10, r11, r12

// 3-operand MUL (V850E1/ES extension)
// CHECK: mul r10, r11, r12 ; encoding: [0xea,0x5f,0x22,0x62]
mul r10, r11, r12

// LD.BU - Load byte unsigned (V850E1/ES extension)
// CHECK: ld.bu 4[r10], r12 ; encoding: [0x8a,0x67,0x04,0x00]
ld.bu 4[r10], r12

// ZXH - Zero extend halfword (V850E1/ES extension)
// CHECK: zxh r10 ; encoding: [0xca,0x00]
zxh r10

//===----------------------------------------------------------------------===//
// Test system register access
// V850ES should accept base system registers (EIPC, EIPSW, FEPC, FEPSW, ECR, PSW)
//===----------------------------------------------------------------------===//

// CHECK: ldsr r10, eipc ; encoding: [0xe0,0x57,0x00,0x04]
ldsr r10, eipc

// CHECK: ldsr r11, psw ; encoding: [0xe5,0x5f,0x00,0x04]
ldsr r11, psw

// CHECK: stsr eipc, r10 ; encoding: [0xe0,0x57,0x80,0x04]
stsr eipc, r10

// CHECK: stsr psw, r11 ; encoding: [0xe5,0x5f,0x80,0x04]
stsr psw, r11

//===----------------------------------------------------------------------===//
// Note: V850ES also accepts CTPC, DIR, etc. at compile time
// The hardware will not support these registers, but the compiler does not
// enforce this restriction. This is documented behavior.
//===----------------------------------------------------------------------===//
