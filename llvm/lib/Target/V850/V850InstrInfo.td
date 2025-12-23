//===-- V850InstrInfo.td - V850 Instruction defs ----------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file describes the V850 instructions in TableGen format.
//
//===----------------------------------------------------------------------===//

include "V850InstrFormats.td"

//===----------------------------------------------------------------------===//
// V850 Operand Definitions
//===----------------------------------------------------------------------===//

// Signed 5-bit immediate
def simm5 : Operand<i32>, ImmLeaf<i32, [{return isInt<5>(Imm);}]> {
  let DecoderMethod = "decodeSImm<5>";
}

// Unsigned 5-bit immediate
def uimm5 : Operand<i32>, ImmLeaf<i32, [{return isUInt<5>(Imm);}]> {
  let DecoderMethod = "decodeUImmOperand<5>";
}

// Signed 16-bit immediate
def simm16 : Operand<i32>, ImmLeaf<i32, [{return isInt<16>(Imm);}]> {
  let DecoderMethod = "decodeSImm<16>";
}

// Unsigned 16-bit immediate
def uimm16 : Operand<i32>, ImmLeaf<i32, [{return isUInt<16>(Imm);}]> {
  let DecoderMethod = "decodeUImmOperand<16>";
}

// 3-bit unsigned immediate (for bit manipulation)
def uimm3 : Operand<i32>, ImmLeaf<i32, [{return isUInt<3>(Imm);}]> {
  let DecoderMethod = "decodeUImmOperand<3>";
}

// 7-bit unsigned immediate (for short load/store displacement)
def uimm7 : Operand<i32>, ImmLeaf<i32, [{return isUInt<7>(Imm);}]> {
  let DecoderMethod = "decodeUImmOperand<7>";
}

// AsmOperandClass for short load/store displacement with implicit EP base
def Imm7AsmOperand : AsmOperandClass {
  let Name = "Imm7EP";
  let RenderMethod = "addImmOperands";
}

// 7-bit displacement with implicit EP base (for short load/store)
// Printed as "disp[ep]" format, but only disp is the actual operand
def disp7ep : Operand<i32>, ImmLeaf<i32, [{return isUInt<7>(Imm);}]> {
  let PrintMethod = "printDisp7EP";
  let DecoderMethod = "decodeUImmOperand<7>";
  let ParserMatchClass = Imm7AsmOperand;
}

// 9-bit PC-relative branch target (bit 0 implicitly 0)
def brtarget9 : Operand<OtherVT> {
  let EncoderMethod = "getBranchTarget9OpValue";
  let DecoderMethod = "decodeBranchTarget9";
}

// 22-bit PC-relative branch target (bit 0 implicitly 0)
def brtarget22 : Operand<OtherVT> {
  let EncoderMethod = "getBranchTarget22OpValue";
  let DecoderMethod = "decodeBranchTarget22";
}

// Condition code operand for SETF instruction
def condcode : Operand<i32> {
  let PrintMethod = "printCondCode";
}

//===----------------------------------------------------------------------===//
// Instruction Pattern Stuff
//===----------------------------------------------------------------------===//

// Call sequence nodes - these are target-independent nodes but have
// target-specific formats.
def SDT_V850CallSeqStart : SDCallSeqStart<[SDTCisVT<0, i32>,
                                           SDTCisVT<1, i32>]>;
def SDT_V850CallSeqEnd   : SDCallSeqEnd<[SDTCisVT<0, i32>,
                                         SDTCisVT<1, i32>]>;

def SDT_V850Call : SDTypeProfile<0, -1, [SDTCisVT<0, i32>]>;

def CallSeqStart : SDNode<"ISD::CALLSEQ_START", SDT_V850CallSeqStart,
                          [SDNPHasChain, SDNPOutGlue]>;
def CallSeqEnd   : SDNode<"ISD::CALLSEQ_END", SDT_V850CallSeqEnd,
                          [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue]>;

def V850Call     : SDNode<"V850ISD::CALL", SDT_V850Call,
                          [SDNPHasChain, SDNPOutGlue, SDNPOptInGlue,
                           SDNPVariadic]>;

def V850RetGlue  : SDNode<"V850ISD::RET_GLUE", SDTNone,
                          [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

def V850Wrapper  : SDNode<"V850ISD::WRAPPER", SDTIntUnaryOp>;

//===----------------------------------------------------------------------===//
// Pseudo Instructions
//===----------------------------------------------------------------------===//

let Defs = [SP], Uses = [SP], hasSideEffects = 0 in {
def ADJCALLSTACKDOWN : V850Pseudo<(outs), (ins i32imm:$amt, i32imm:$amt2),
                                  "# ADJCALLSTACKDOWN $amt, $amt2",
                                  [(CallSeqStart timm:$amt, timm:$amt2)]>;
def ADJCALLSTACKUP   : V850Pseudo<(outs), (ins i32imm:$amt1, i32imm:$amt2),
                                  "# ADJCALLSTACKUP $amt1, $amt2",
                                  [(CallSeqEnd timm:$amt1, timm:$amt2)]>;
}

//===----------------------------------------------------------------------===//
// NOP Instruction
//===----------------------------------------------------------------------===//

// NOP is encoded as MOV r0, r0 (opcode 0x0000)
let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
def NOP : V850Inst16<(outs), (ins), "nop", []> {
  let Inst{15-0} = 0x0000;
}

//===----------------------------------------------------------------------===//
// Return Instruction
//===----------------------------------------------------------------------===//

let isReturn = 1, isTerminator = 1, isBarrier = 1, Uses = [LP] in
def RET : V850Pseudo<(outs), (ins), "jmp\t[lp]", [(V850RetGlue)]>;

//===----------------------------------------------------------------------===//
// Arithmetic Instructions - Format I (Register-Register)
//===----------------------------------------------------------------------===//

// ADD reg1, reg2 - Add reg1 to reg2, store in reg2
// Opcode: 001110 (0x0E)
let Constraints = "$rs = $reg2" in
def ADD : FormatI<0b001110, (outs GPR:$reg2), (ins GPR:$rs, GPR:$reg1),
                  "add\t$reg1, $reg2",
                  [(set GPR:$reg2, (add GPR:$rs, GPR:$reg1))]>;

// SUB reg1, reg2 - Subtract reg1 from reg2, store in reg2
// Opcode: 001101 (0x0D)
let Constraints = "$rs = $reg2" in
def SUB : FormatI<0b001101, (outs GPR:$reg2), (ins GPR:$rs, GPR:$reg1),
                  "sub\t$reg1, $reg2",
                  [(set GPR:$reg2, (sub GPR:$rs, GPR:$reg1))]>;

// SUBR reg1, reg2 - Subtract reg2 from reg1, store in reg2 (reverse subtract)
// Opcode: 001100 (0x0C)
let Constraints = "$rs = $reg2" in
def SUBR : FormatI<0b001100, (outs GPR:$reg2), (ins GPR:$rs, GPR:$reg1),
                   "subr\t$reg1, $reg2",
                   []>;

// CMP reg1, reg2 - Compare reg2 with reg1 (sets flags only)
// Opcode: 001111 (0x0F)
let Defs = [PSW], hasSideEffects = 0 in
def CMP : FormatI<0b001111, (outs), (ins GPR:$reg2, GPR:$reg1),
                  "cmp\t$reg1, $reg2",
                  []>;

// MOV reg1, reg2 - Move reg1 to reg2
// Opcode: 000000 (0x00)
def MOV : FormatI<0b000000, (outs GPR:$reg2), (ins GPR:$reg1),
                  "mov\t$reg1, $reg2",
                  []>;

// NOT reg1, reg2 - Bitwise NOT of reg1, store in reg2
// Opcode: 000001 (0x01)
def NOT : FormatI<0b000001, (outs GPR:$reg2), (ins GPR:$reg1),
                  "not\t$reg1, $reg2",
                  [(set GPR:$reg2, (not GPR:$reg1))]>;

// DIVH reg1, reg2 - Divide halfword (reg2/reg1 -> reg2)
// Opcode: 000010 (0x02)
let Constraints = "$rs = $reg2" in
def DIVH : FormatI<0b000010, (outs GPR:$reg2), (ins GPR:$rs, GPR:$reg1),
                   "divh\t$reg1, $reg2",
                   []>;

// JMP [reg1] - Jump to address in reg1
// Opcode: 000011 (0x03)
let isTerminator = 1, isBarrier = 1, isBranch = 1, isIndirectBranch = 1 in
def JMP : FormatI<0b000011, (outs), (ins GPR:$reg1),
                  "jmp\t[$reg1]",
                  [(brind GPR:$reg1)]> {
  let reg2 = 0;
}

// SATSUBR reg1, reg2 - Saturated subtract reverse
// Opcode: 000100 (0x04)
let Constraints = "$rs = $reg2" in
def SATSUBR : FormatI<0b000100, (outs GPR:$reg2), (ins GPR:$rs, GPR:$reg1),
                      "satsubr\t$reg1, $reg2",
                      []>;

// SATSUB reg1, reg2 - Saturated subtract
// Opcode: 000101 (0x05)
let Constraints = "$rs = $reg2" in
def SATSUB : FormatI<0b000101, (outs GPR:$reg2), (ins GPR:$rs, GPR:$reg1),
                     "satsub\t$reg1, $reg2",
                     []>;

// SATADD reg1, reg2 - Saturated add
// Opcode: 000110 (0x06)
let Constraints = "$rs = $reg2" in
def SATADD : FormatI<0b000110, (outs GPR:$reg2), (ins GPR:$rs, GPR:$reg1),
                     "satadd\t$reg1, $reg2",
                     []>;

// MULH reg1, reg2 - Multiply halfword (16x16 -> 32)
// Opcode: 000111 (0x07)
let Constraints = "$rs = $reg2" in
def MULH : FormatI<0b000111, (outs GPR:$reg2), (ins GPR:$rs, GPR:$reg1),
                   "mulh\t$reg1, $reg2",
                   []>;

// OR reg1, reg2 - Bitwise OR
// Opcode: 001000 (0x08)
let Constraints = "$rs = $reg2" in
def OR : FormatI<0b001000, (outs GPR:$reg2), (ins GPR:$rs, GPR:$reg1),
                 "or\t$reg1, $reg2",
                 [(set GPR:$reg2, (or GPR:$rs, GPR:$reg1))]>;

// XOR reg1, reg2 - Bitwise XOR
// Opcode: 001001 (0x09)
let Constraints = "$rs = $reg2" in
def XOR : FormatI<0b001001, (outs GPR:$reg2), (ins GPR:$rs, GPR:$reg1),
                  "xor\t$reg1, $reg2",
                  [(set GPR:$reg2, (xor GPR:$rs, GPR:$reg1))]>;

// AND reg1, reg2 - Bitwise AND
// Opcode: 001010 (0x0A)
let Constraints = "$rs = $reg2" in
def AND : FormatI<0b001010, (outs GPR:$reg2), (ins GPR:$rs, GPR:$reg1),
                  "and\t$reg1, $reg2",
                  [(set GPR:$reg2, (and GPR:$rs, GPR:$reg1))]>;

// TST reg1, reg2 - Test (AND without storing result, sets flags)
// Opcode: 001011 (0x0B)
let Defs = [PSW], hasSideEffects = 0 in
def TST : FormatI<0b001011, (outs), (ins GPR:$reg2, GPR:$reg1),
                  "tst\t$reg1, $reg2",
                  []>;

//===----------------------------------------------------------------------===//
// Arithmetic Instructions - Format II (Immediate-Register)
//===----------------------------------------------------------------------===//

// MOV imm5, reg2 - Move sign-extended 5-bit immediate to reg2
// Opcode: 010000 (0x10)
def MOVi : FormatII<0b010000, (outs GPR:$reg2), (ins simm5:$imm5),
                    "mov\t$imm5, $reg2",
                    [(set GPR:$reg2, simm5:$imm5)]>;

// SATADD imm5, reg2 - Saturated add immediate
// Opcode: 010001 (0x11)
let Constraints = "$rs = $reg2" in
def SATADDi : FormatII<0b010001, (outs GPR:$reg2), (ins GPR:$rs, simm5:$imm5),
                       "satadd\t$imm5, $reg2",
                       []>;

// ADD imm5, reg2 - Add sign-extended 5-bit immediate to reg2
// Opcode: 010010 (0x12)
let Constraints = "$rs = $reg2" in
def ADDi : FormatII<0b010010, (outs GPR:$reg2), (ins simm5:$imm5, GPR:$rs),
                    "add\t$imm5, $reg2",
                    [(set GPR:$reg2, (add GPR:$rs, simm5:$imm5))]>;

// CMP imm5, reg2 - Compare reg2 with sign-extended 5-bit immediate
// Opcode: 010011 (0x13)
let Defs = [PSW], hasSideEffects = 0 in
def CMPi : FormatII<0b010011, (outs), (ins GPR:$reg2, simm5:$imm5),
                    "cmp\t$imm5, $reg2",
                    []>;

// SHR imm5, reg2 - Shift right logical by immediate
// Opcode: 010100 (0x14)
let Constraints = "$rs = $reg2" in
def SHRi : FormatII<0b010100, (outs GPR:$reg2), (ins GPR:$rs, uimm5:$imm5),
                    "shr\t$imm5, $reg2",
                    [(set GPR:$reg2, (srl GPR:$rs, uimm5:$imm5))]>;

// SAR imm5, reg2 - Shift right arithmetic by immediate
// Opcode: 010101 (0x15)
let Constraints = "$rs = $reg2" in
def SARi : FormatII<0b010101, (outs GPR:$reg2), (ins GPR:$rs, uimm5:$imm5),
                    "sar\t$imm5, $reg2",
                    [(set GPR:$reg2, (sra GPR:$rs, uimm5:$imm5))]>;

// SHL imm5, reg2 - Shift left logical by immediate
// Opcode: 010110 (0x16)
let Constraints = "$rs = $reg2" in
def SHLi : FormatII<0b010110, (outs GPR:$reg2), (ins GPR:$rs, uimm5:$imm5),
                    "shl\t$imm5, $reg2",
                    [(set GPR:$reg2, (shl GPR:$rs, uimm5:$imm5))]>;

// MULH imm5, reg2 - Multiply halfword with immediate
// Opcode: 010111 (0x17)
let Constraints = "$rs = $reg2" in
def MULHi : FormatII<0b010111, (outs GPR:$reg2), (ins GPR:$rs, simm5:$imm5),
                     "mulh\t$imm5, $reg2",
                     []>;

//===----------------------------------------------------------------------===//
// Arithmetic Instructions - Format VI (3-operand with 16-bit immediate)
//===----------------------------------------------------------------------===//

// ADDI imm16, reg1, reg2 - Add 16-bit immediate to reg1, store in reg2
// Opcode: 110000 (0x30)
def ADDI : FormatVI<0b110000, (outs GPR:$reg2), (ins GPR:$reg1, simm16:$imm16),
                    "addi\t$imm16, $reg1, $reg2",
                    [(set GPR:$reg2, (add GPR:$reg1, simm16:$imm16))]>;

// MOVEA imm16, reg1, reg2 - Move effective address (add signed imm16)
// Opcode: 110001 (0x31)
def MOVEA : FormatVI<0b110001, (outs GPR:$reg2), (ins GPR:$reg1, simm16:$imm16),
                     "movea\t$imm16, $reg1, $reg2",
                     [(set GPR:$reg2, (add GPR:$reg1, simm16:$imm16))]>;

// MOVHI imm16, reg1, reg2 - Move high (add imm16 << 16 to reg1)
// Opcode: 110010 (0x32)
def MOVHI : FormatVI<0b110010, (outs GPR:$reg2), (ins GPR:$reg1, uimm16:$imm16),
                     "movhi\t$imm16, $reg1, $reg2",
                     []>;

// SATSUBI imm16, reg1, reg2 - Saturated subtract immediate
// Opcode: 110011 (0x33)
def SATSUBI : FormatVI<0b110011, (outs GPR:$reg2), (ins GPR:$reg1, simm16:$imm16),
                       "satsubi\t$imm16, $reg1, $reg2",
                       []>;

// ORI imm16, reg1, reg2 - OR with zero-extended immediate
// Opcode: 110100 (0x34)
def ORI : FormatVI<0b110100, (outs GPR:$reg2), (ins GPR:$reg1, uimm16:$imm16),
                   "ori\t$imm16, $reg1, $reg2",
                   [(set GPR:$reg2, (or GPR:$reg1, uimm16:$imm16))]>;

// XORI imm16, reg1, reg2 - XOR with zero-extended immediate
// Opcode: 110101 (0x35)
def XORI : FormatVI<0b110101, (outs GPR:$reg2), (ins GPR:$reg1, uimm16:$imm16),
                    "xori\t$imm16, $reg1, $reg2",
                    [(set GPR:$reg2, (xor GPR:$reg1, uimm16:$imm16))]>;

// ANDI imm16, reg1, reg2 - AND with zero-extended immediate
// Opcode: 110110 (0x36)
def ANDI : FormatVI<0b110110, (outs GPR:$reg2), (ins GPR:$reg1, uimm16:$imm16),
                    "andi\t$imm16, $reg1, $reg2",
                    [(set GPR:$reg2, (and GPR:$reg1, uimm16:$imm16))]>;

// MULHI imm16, reg1, reg2 - Multiply high immediate
// Opcode: 110111 (0x37)
def MULHI : FormatVI<0b110111, (outs GPR:$reg2), (ins GPR:$reg1, simm16:$imm16),
                     "mulhi\t$imm16, $reg1, $reg2",
                     []>;

//===----------------------------------------------------------------------===//
// Conditional Branch Instructions - Format III
//===----------------------------------------------------------------------===//

// Bcond class for conditional branches
// Opcode: 1011 (4 bits)
class Bcond<bits<4> cc, string mnemonic>
    : FormatIII<0b1011, (outs), (ins brtarget9:$disp9),
                mnemonic # "\t$disp9", []> {
  let cond = cc;
  let isBranch = 1;
  let isTerminator = 1;
}

def BV   : Bcond<0b0000, "bv">;    // Overflow
def BC   : Bcond<0b0001, "bc">;    // Carry (also BL - Lower)
def BZ   : Bcond<0b0010, "bz">;    // Zero (also BE - Equal)
def BNH  : Bcond<0b0011, "bnh">;   // Not higher
def BN   : Bcond<0b0100, "bn">;    // Negative
def BR   : Bcond<0b0101, "br">;    // Always (unconditional)
def BLT  : Bcond<0b0110, "blt">;   // Less than (signed)
def BLE  : Bcond<0b0111, "ble">;   // Less or equal (signed)
def BNV  : Bcond<0b1000, "bnv">;   // No overflow
def BNC  : Bcond<0b1001, "bnc">;   // No carry (also BNL - Not lower)
def BNZ  : Bcond<0b1010, "bnz">;   // Not zero (also BNE - Not equal)
def BH   : Bcond<0b1011, "bh">;    // Higher
def BP   : Bcond<0b1100, "bp">;    // Positive
def BSA  : Bcond<0b1101, "bsa">;   // Saturated
def BGE  : Bcond<0b1110, "bge">;   // Greater or equal (signed)
def BGT  : Bcond<0b1111, "bgt">;   // Greater than (signed)

// TODO: Add aliases for alternate mnemonics when AsmParser is implemented
// def : InstAlias<"bl $disp9", (BC brtarget9:$disp9)>;
// def : InstAlias<"be $disp9", (BZ brtarget9:$disp9)>;
// def : InstAlias<"bne $disp9", (BNZ brtarget9:$disp9)>;
// def : InstAlias<"bnl $disp9", (BNC brtarget9:$disp9)>;

//===----------------------------------------------------------------------===//
// Jump Instructions - Format V (32-bit)
//===----------------------------------------------------------------------===//

// JR disp22 - Jump relative (PC-relative unconditional)
// Opcode: 101111 (0x2F), reg2 = 0
let isBranch = 1, isTerminator = 1, isBarrier = 1 in
def JR : FormatV<0b101111, (outs), (ins brtarget22:$disp22),
                 "jr\t$disp22",
                 [(br bb:$disp22)]> {
  let reg2 = 0;
}

// JARL disp22, reg2 - Jump and register link
// Opcode: 101111 (0x2F)
let isCall = 1, Defs = [LP] in
def JARL : FormatV<0b101111, (outs GPR:$reg2), (ins brtarget22:$disp22),
                   "jarl\t$disp22, $reg2",
                   []>;

//===----------------------------------------------------------------------===//
// Extended Instructions - Format IX (32-bit)
//===----------------------------------------------------------------------===//

// SETF cccc, reg2 - Set flag (set reg2 to 1 if condition true, else 0)
// Opcode: 111111 (0x3F), sub-op: 000000
// Note: Only lower 4 bits of reg1 field are used for condition code
def SETF : FormatIX<0b111111, 0b000000, (outs GPR:$reg2), (ins condcode:$cond),
                    "setf\t$cond, $reg2",
                    []> {
  bits<5> cond;  // 5 bits to match reg1 field, but only lower 4 used
  let reg1 = cond;
}

// LDSR reg2, regID - Load to system register
// Opcode: 111111 (0x3F), sub-op: 100000 (0x20)
def LDSR : FormatIX<0b111111, 0b100000, (outs), (ins GPR:$reg2, SysReg:$regID),
                    "ldsr\t$reg2, $regID",
                    []> {
  bits<5> regID;
  let reg1 = regID;
}

// STSR regID, reg2 - Store from system register
// Opcode: 111111 (0x3F), sub-op: 100100 (0x24)
def STSR : FormatIX<0b111111, 0b100100, (outs GPR:$reg2), (ins SysReg:$regID),
                    "stsr\t$regID, $reg2",
                    []> {
  bits<5> regID;
  let reg1 = regID;
}

// SHR reg1, reg2 - Shift right logical by register
// Opcode: 111111 (0x3F), sub-op: 000010 (0x02)
let Constraints = "$rs = $reg2" in
def SHR : FormatIX<0b111111, 0b000010, (outs GPR:$reg2), (ins GPR:$rs, GPR:$reg1),
                   "shr\t$reg1, $reg2",
                   [(set GPR:$reg2, (srl GPR:$rs, GPR:$reg1))]>;

// SAR reg1, reg2 - Shift right arithmetic by register
// Opcode: 111111 (0x3F), sub-op: 000100 (0x04)
let Constraints = "$rs = $reg2" in
def SAR : FormatIX<0b111111, 0b000100, (outs GPR:$reg2), (ins GPR:$rs, GPR:$reg1),
                   "sar\t$reg1, $reg2",
                   [(set GPR:$reg2, (sra GPR:$rs, GPR:$reg1))]>;

// SHL reg1, reg2 - Shift left logical by register
// Opcode: 111111 (0x3F), sub-op: 000110
let Constraints = "$rs = $reg2" in
def SHL : FormatIX<0b111111, 0b000110, (outs GPR:$reg2), (ins GPR:$rs, GPR:$reg1),
                   "shl\t$reg1, $reg2",
                   [(set GPR:$reg2, (shl GPR:$rs, GPR:$reg1))]>;

//===----------------------------------------------------------------------===//
// Special Instructions - Format X (32-bit)
//===----------------------------------------------------------------------===//

// TRAP vector - Software trap
// Opcode: 111111 (0x3F), sub-op: 010000
let hasSideEffects = 1 in
def TRAP : FormatX<0b111111, 0b010000, (outs), (ins uimm5:$vector),
                   "trap\t$vector",
                   []>;

// HALT - Halt CPU
// Opcode: 111111 (0x3F), sub-op: 010010
let hasSideEffects = 1 in
def HALT : FormatX<0b111111, 0b010010, (outs), (ins),
                   "halt",
                   []> {
  let vector = 0;
}

// RETI - Return from interrupt/exception
// Opcode: 111111 (0x3F), sub-op: 010100
let isReturn = 1, isTerminator = 1, isBarrier = 1, hasSideEffects = 1 in
def RETI : FormatX<0b111111, 0b010100, (outs), (ins),
                   "reti",
                   []> {
  let vector = 0;
}

// DI - Disable interrupts
// Opcode: 111111 (0x3F), sub-op: 010110
let Defs = [PSW], hasSideEffects = 1 in
def DI : FormatX<0b111111, 0b010110, (outs), (ins),
                 "di",
                 []> {
  let vector = 0;
}

// EI - Enable interrupts
// Opcode: 111111 (0x3F), sub-op: 100110
let Defs = [PSW], hasSideEffects = 1 in
def EI : FormatX<0b111111, 0b100110, (outs), (ins),
                 "ei",
                 []> {
  let vector = 0;
}

//===----------------------------------------------------------------------===//
// Load/Store Instructions - Format VII (32-bit)
//===----------------------------------------------------------------------===//

// LD.B disp16[reg1], reg2 - Load byte (sign-extended)
// Opcode: 111000 (0x38)
let mayLoad = 1 in
def LDB : FormatVII<0b111000, (outs GPR:$reg2), (ins GPR:$reg1, simm16:$disp16),
                    "ld.b\t$disp16[$reg1], $reg2",
                    []>;

// LD.H disp16[reg1], reg2 - Load halfword (sign-extended)
// Opcode: 111001 (0x39), bit 16 = 0
let mayLoad = 1 in
def LDH : FormatVII<0b111001, (outs GPR:$reg2), (ins GPR:$reg1, simm16:$disp16),
                    "ld.h\t$disp16[$reg1], $reg2",
                    []> {
  // Halfword load: bit 16 = 0
  let Inst{16} = 0;
}

// LD.W disp16[reg1], reg2 - Load word
// Opcode: 111001 (0x39), bit 16 = 1
let mayLoad = 1 in
def LDW : FormatVII<0b111001, (outs GPR:$reg2), (ins GPR:$reg1, simm16:$disp16),
                    "ld.w\t$disp16[$reg1], $reg2",
                    []> {
  // Word load: bit 16 = 1
  let Inst{16} = 1;
}

// ST.B reg2, disp16[reg1] - Store byte
// Opcode: 111010 (0x3A)
let mayStore = 1 in
def STB : FormatVII<0b111010, (outs), (ins GPR:$reg2, GPR:$reg1, simm16:$disp16),
                    "st.b\t$reg2, $disp16[$reg1]",
                    []>;

// ST.H reg2, disp16[reg1] - Store halfword
// Opcode: 111011 (0x3B), bit 16 = 0
let mayStore = 1 in
def STH : FormatVII<0b111011, (outs), (ins GPR:$reg2, GPR:$reg1, simm16:$disp16),
                    "st.h\t$reg2, $disp16[$reg1]",
                    []> {
  let Inst{16} = 0;
}

// ST.W reg2, disp16[reg1] - Store word
// Opcode: 111011 (0x3B), bit 16 = 1
let mayStore = 1 in
def STW : FormatVII<0b111011, (outs), (ins GPR:$reg2, GPR:$reg1, simm16:$disp16),
                    "st.w\t$reg2, $disp16[$reg1]",
                    []> {
  let Inst{16} = 1;
}

//===----------------------------------------------------------------------===//
// Short Load/Store Instructions - Format IV (16-bit)
//===----------------------------------------------------------------------===//

// SLD.B disp7[ep], reg2 - Short load byte (uses EP as base)
// Opcode: 0110 (0x6)
let mayLoad = 1, Uses = [EP] in
def SLDB : FormatIV<0b0110, (outs GPR:$reg2), (ins disp7ep:$disp7),
                    "sld.b\t$disp7, $reg2",
                    []>;

// SLD.H disp8[ep], reg2 - Short load halfword (uses EP as base)
// Opcode: 1000 (0x8)
let mayLoad = 1, Uses = [EP] in
def SLDH : FormatIV<0b1000, (outs GPR:$reg2), (ins disp7ep:$disp7),
                    "sld.h\t$disp7, $reg2",
                    []>;

// SLD.W disp8[ep], reg2 - Short load word (uses EP as base)
// Opcode: 1010 (0xA), bit 0 = 1
let mayLoad = 1, Uses = [EP] in
def SLDW : FormatIV<0b1010, (outs GPR:$reg2), (ins disp7ep:$disp7),
                    "sld.w\t$disp7, $reg2",
                    []> {
  let Inst{0} = 1;
}

// SST.B reg2, disp7[ep] - Short store byte (uses EP as base)
// Opcode: 0111 (0x7)
let mayStore = 1, Uses = [EP] in
def SSTB : FormatIV<0b0111, (outs), (ins GPR:$reg2, disp7ep:$disp7),
                    "sst.b\t$reg2, $disp7",
                    []>;

// SST.H reg2, disp8[ep] - Short store halfword (uses EP as base)
// Opcode: 1001 (0x9)
let mayStore = 1, Uses = [EP] in
def SSTH : FormatIV<0b1001, (outs), (ins GPR:$reg2, disp7ep:$disp7),
                    "sst.h\t$reg2, $disp7",
                    []>;

// SST.W reg2, disp8[ep] - Short store word (uses EP as base)
// Opcode: 1010 (0xA), bit 0 = 0
let mayStore = 1, Uses = [EP] in
def SSTW : FormatIV<0b1010, (outs), (ins GPR:$reg2, disp7ep:$disp7),
                    "sst.w\t$reg2, $disp7",
                    []> {
  let Inst{0} = 0;
}

//===----------------------------------------------------------------------===//
// Bit Manipulation Instructions - Format VIII (32-bit)
//===----------------------------------------------------------------------===//

// SET1 bit#3, disp16[reg1] - Set bit in memory
// Opcode: 111110 (0x3E), sub-op: 00
// Note: Assembly syntax is "set1 bit, disp[reg]" but operand order is bit, reg, disp
let mayLoad = 1, mayStore = 1 in
def SET1 : FormatVIII<0b111110, 0b00, (outs),
                      (ins uimm3:$bit3, GPR:$reg1, simm16:$disp16),
                      "set1\t$bit3, $disp16[$reg1]",
                      []>;

// NOT1 bit#3, disp16[reg1] - Toggle bit in memory
// Opcode: 111110 (0x3E), sub-op: 01
let mayLoad = 1, mayStore = 1 in
def NOT1 : FormatVIII<0b111110, 0b01, (outs),
                      (ins uimm3:$bit3, GPR:$reg1, simm16:$disp16),
                      "not1\t$bit3, $disp16[$reg1]",
                      []>;

// CLR1 bit#3, disp16[reg1] - Clear bit in memory
// Opcode: 111110 (0x3E), sub-op: 10
let mayLoad = 1, mayStore = 1 in
def CLR1 : FormatVIII<0b111110, 0b10, (outs),
                      (ins uimm3:$bit3, GPR:$reg1, simm16:$disp16),
                      "clr1\t$bit3, $disp16[$reg1]",
                      []>;

// TST1 bit#3, disp16[reg1] - Test bit in memory
// Opcode: 111110 (0x3E), sub-op: 11
let mayLoad = 1, Defs = [PSW] in
def TST1 : FormatVIII<0b111110, 0b11, (outs),
                      (ins uimm3:$bit3, GPR:$reg1, simm16:$disp16),
                      "tst1\t$bit3, $disp16[$reg1]",
                      []>;

