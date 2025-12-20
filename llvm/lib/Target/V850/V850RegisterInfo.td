//===-- V850RegisterInfo.td - V850 Register defs ----------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Declarations that describe the V850 register file.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// V850 Register Class Definitions
//===----------------------------------------------------------------------===//

class V850Reg<bits<5> Enc, string n, list<string> altNames = []>
    : Register<n, altNames> {
  let HWEncoding{4-0} = Enc;
  let Namespace = "V850";
}

//===----------------------------------------------------------------------===//
// General Purpose Registers (r0-r31)
//===----------------------------------------------------------------------===//

// r0 - Zero register (always reads as 0)
def R0 : V850Reg<0, "r0", ["zero"]>;

// r1 - Assembler reserved register
def R1 : V850Reg<1, "r1">;

// r2 - Variable/RTOS register
def R2 : V850Reg<2, "r2">;

// r3 - Stack Pointer
def SP : V850Reg<3, "r3", ["sp"]>;

// r4 - Global Pointer
def GP : V850Reg<4, "r4", ["gp"]>;

// r5 - Text Pointer
def TP : V850Reg<5, "r5", ["tp"]>;

// r6-r29 - General purpose registers
def R6  : V850Reg<6,  "r6">;
def R7  : V850Reg<7,  "r7">;
def R8  : V850Reg<8,  "r8">;
def R9  : V850Reg<9,  "r9">;
def R10 : V850Reg<10, "r10">;
def R11 : V850Reg<11, "r11">;
def R12 : V850Reg<12, "r12">;
def R13 : V850Reg<13, "r13">;
def R14 : V850Reg<14, "r14">;
def R15 : V850Reg<15, "r15">;
def R16 : V850Reg<16, "r16">;
def R17 : V850Reg<17, "r17">;
def R18 : V850Reg<18, "r18">;
def R19 : V850Reg<19, "r19">;
def R20 : V850Reg<20, "r20">;
def R21 : V850Reg<21, "r21">;
def R22 : V850Reg<22, "r22">;
def R23 : V850Reg<23, "r23">;
def R24 : V850Reg<24, "r24">;
def R25 : V850Reg<25, "r25">;
def R26 : V850Reg<26, "r26">;
def R27 : V850Reg<27, "r27">;
def R28 : V850Reg<28, "r28">;
def R29 : V850Reg<29, "r29">;

// r30 - Element Pointer (used as base for SLD/SST short-format memory access)
def EP : V850Reg<30, "r30", ["ep"]>;

// r31 - Link Pointer (return address)
def LP : V850Reg<31, "r31", ["lp"]>;

//===----------------------------------------------------------------------===//
// Register Classes
//===----------------------------------------------------------------------===//

// General purpose register class - all 32 registers
def GPR : RegisterClass<"V850", [i32], 32,
    (add R0, R1, R2, SP, GP, TP,
         R6, R7, R8, R9, R10, R11, R12, R13, R14, R15,
         R16, R17, R18, R19, R20, R21, R22, R23, R24, R25,
         R26, R27, R28, R29, EP, LP)>;

// GPR class excluding r0 (for destinations that can't be r0)
def GPRnoR0 : RegisterClass<"V850", [i32], 32,
    (sub GPR, R0)>;

//===----------------------------------------------------------------------===//
// System Registers
//===----------------------------------------------------------------------===//

class V850SysReg<bits<5> Enc, string n> : Register<n> {
  let HWEncoding{4-0} = Enc;
  let Namespace = "V850";
}

def EIPC  : V850SysReg<0, "eipc">;   // Exception/Interrupt PC
def EIPSW : V850SysReg<1, "eipsw">;  // Exception/Interrupt PSW
def FEPC  : V850SysReg<2, "fepc">;   // Fatal Error PC
def FEPSW : V850SysReg<3, "fepsw">;  // Fatal Error PSW
def ECR   : V850SysReg<4, "ecr">;    // Exception Cause Register
def PSW   : V850SysReg<5, "psw">;    // Program Status Word

// System register class
def SysReg : RegisterClass<"V850", [i32], 32,
    (add EIPC, EIPSW, FEPC, FEPSW, ECR, PSW)> {
  let isAllocatable = 0;
}
