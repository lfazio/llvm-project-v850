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
// V850 has 32 general-purpose 32-bit registers (r0-r31):
//   r0       - Zero register (always reads as 0, writes ignored)
//   r1       - Assembler reserved (for address generation)
//   r2       - Reserved for RTOS/variable
//   r3 (SP)  - Stack Pointer
//   r4 (GP)  - Global Pointer (global data area access)
//   r5 (TP)  - Text Pointer (text area start address)
//   r6-r9    - Argument/result registers (caller-saved)
//   r10-r19  - Caller-saved temporary registers
//   r20-r29  - Callee-saved registers
//   r30 (EP) - Element Pointer (SLD/SST base for short-format memory access)
//   r31 (LP) - Link Pointer (return address)
//
// System registers (accessed via LDSR/STSR):
//   0 - EIPC  (Exception/Interrupt PC)
//   1 - EIPSW (Exception/Interrupt PSW)
//   2 - FEPC  (Fatal Error PC)
//   3 - FEPSW (Fatal Error PSW)
//   4 - ECR   (Exception Cause Register, read-only via STSR)
//   5 - PSW   (Program Status Word)
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

// r0 - Zero register (always reads as 0, writes are ignored)
def R0 : V850Reg<0, "r0", ["zero"]>, DwarfRegNum<[0]>;

// r1 - Assembler reserved register (used for address generation helpers)
let CostPerUse = [1] in
def R1 : V850Reg<1, "r1">, DwarfRegNum<[1]>;

// r2 - Variable/RTOS register (may be used by real-time OS)
let CostPerUse = [1] in
def R2 : V850Reg<2, "r2">, DwarfRegNum<[2]>;

// r3 - Stack Pointer
let CostPerUse = [1] in
def SP : V850Reg<3, "r3", ["sp"]>, DwarfRegNum<[3]>;

// r4 - Global Pointer (global data area access)
let CostPerUse = [1] in
def GP : V850Reg<4, "r4", ["gp"]>, DwarfRegNum<[4]>;

// r5 - Text Pointer (text area start address)
let CostPerUse = [1] in
def TP : V850Reg<5, "r5", ["tp"]>, DwarfRegNum<[5]>;

// r6-r9 - Argument/result registers (caller-saved)
def R6  : V850Reg<6,  "r6">, DwarfRegNum<[6]>;
def R7  : V850Reg<7,  "r7">, DwarfRegNum<[7]>;
def R8  : V850Reg<8,  "r8">, DwarfRegNum<[8]>;
def R9  : V850Reg<9,  "r9">, DwarfRegNum<[9]>;

// r10-r19 - Caller-saved temporary registers
def R10 : V850Reg<10, "r10">, DwarfRegNum<[10]>;
def R11 : V850Reg<11, "r11">, DwarfRegNum<[11]>;
def R12 : V850Reg<12, "r12">, DwarfRegNum<[12]>;
def R13 : V850Reg<13, "r13">, DwarfRegNum<[13]>;
def R14 : V850Reg<14, "r14">, DwarfRegNum<[14]>;
def R15 : V850Reg<15, "r15">, DwarfRegNum<[15]>;
def R16 : V850Reg<16, "r16">, DwarfRegNum<[16]>;
def R17 : V850Reg<17, "r17">, DwarfRegNum<[17]>;
def R18 : V850Reg<18, "r18">, DwarfRegNum<[18]>;
def R19 : V850Reg<19, "r19">, DwarfRegNum<[19]>;

// r20-r29 - Callee-saved registers
def R20 : V850Reg<20, "r20">, DwarfRegNum<[20]>;
def R21 : V850Reg<21, "r21">, DwarfRegNum<[21]>;
def R22 : V850Reg<22, "r22">, DwarfRegNum<[22]>;
def R23 : V850Reg<23, "r23">, DwarfRegNum<[23]>;
def R24 : V850Reg<24, "r24">, DwarfRegNum<[24]>;
def R25 : V850Reg<25, "r25">, DwarfRegNum<[25]>;
def R26 : V850Reg<26, "r26">, DwarfRegNum<[26]>;
def R27 : V850Reg<27, "r27">, DwarfRegNum<[27]>;
def R28 : V850Reg<28, "r28">, DwarfRegNum<[28]>;
def R29 : V850Reg<29, "r29">, DwarfRegNum<[29]>;

// r30 - Element Pointer (base for SLD/SST short-format memory access)
let CostPerUse = [1] in
def EP : V850Reg<30, "r30", ["ep"]>, DwarfRegNum<[30]>;

// r31 - Link Pointer (return address for function calls)
let CostPerUse = [1] in
def LP : V850Reg<31, "r31", ["lp"]>, DwarfRegNum<[31]>;

//===----------------------------------------------------------------------===//
// Register Classes
//===----------------------------------------------------------------------===//

// General purpose register class - all 32 registers
// Order: caller-saved temporaries first (preferred for allocation),
// then callee-saved, then special-purpose registers
def GPR : RegisterClass<"V850", [i32], 32,
    (add
     // Caller-saved temporaries (preferred for allocation)
     R10, R11, R12, R13, R14, R15, R16, R17, R18, R19,
     // Argument registers
     R6, R7, R8, R9,
     // Callee-saved registers
     R20, R21, R22, R23, R24, R25, R26, R27, R28, R29,
     // Special-purpose registers (less preferred)
     R1, R2, EP, LP, SP, GP, TP,
     // Zero register (read-only)
     R0
    )>;

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

// Base System Registers (All V850 variants)

// Exception/Interrupt PC - saved PC when exception/interrupt occurs
def EIPC  : V850SysReg<0, "eipc">;

// Exception/Interrupt PSW - saved PSW when exception/interrupt occurs
def EIPSW : V850SysReg<1, "eipsw">;

// Fatal Error PC - saved PC when fatal error (NMI, etc.) occurs
def FEPC  : V850SysReg<2, "fepc">;

// Fatal Error PSW - saved PSW when fatal error occurs
def FEPSW : V850SysReg<3, "fepsw">;

// Exception Cause Register - indicates cause of exception (read-only via STSR)
def ECR   : V850SysReg<4, "ecr">;

// Program Status Word - contains flags (Z, S, OV, CY, SAT) and control bits
def PSW   : V850SysReg<5, "psw">;
