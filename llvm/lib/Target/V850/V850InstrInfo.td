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

// 4-bit unsigned immediate (for FPU condition codes)
def uimm4 : Operand<i32>, ImmLeaf<i32, [{return isUInt<4>(Imm);}]> {
  let DecoderMethod = "decodeUImmOperand<4>";
}

// 7-bit unsigned immediate (for short load/store displacement)
def uimm7 : Operand<i32>, ImmLeaf<i32, [{return isUInt<7>(Imm);}]> {
  let DecoderMethod = "decodeUImmOperand<7>";
}

// 6-bit unsigned immediate (for CALLT)
def uimm6 : Operand<i32>, ImmLeaf<i32, [{return isUInt<6>(Imm);}]> {
  let DecoderMethod = "decodeUImmOperand<6>";
}

// 12-bit unsigned immediate (for PREPARE/DISPOSE register list)
def uimm12 : Operand<i32>, ImmLeaf<i32, [{return isUInt<12>(Imm);}]> {
  let DecoderMethod = "decodeUImmOperand<12>";
}

// Signed 9-bit immediate (for MUL/MULU immediate)
def simm9 : Operand<i32>, ImmLeaf<i32, [{return isInt<9>(Imm);}]> {
  let DecoderMethod = "decodeSImm<9>";
}

// Unsigned 9-bit immediate (for MUL/MULU unsigned immediate)
def uimm9 : Operand<i32>, ImmLeaf<i32, [{return isUInt<9>(Imm);}]> {
  let DecoderMethod = "decodeUImmOperand<9>";
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

// 4-bit displacement for SLD.BU (byte offset 0-15)
def Imm4AsmOperand : AsmOperandClass {
  let Name = "Imm4";
  let RenderMethod = "addImmOperands";
}

def disp4ep : Operand<i32>, ImmLeaf<i32, [{return isUInt<4>(Imm);}]> {
  let PrintMethod = "printDisp4EP";
  let DecoderMethod = "decodeUImmOperand<4>";
  let ParserMatchClass = Imm4AsmOperand;
}

// 5-bit displacement for SLD.HU (halfword offset 0-30, must be even)
def Imm5AsmOperand : AsmOperandClass {
  let Name = "Imm5";
  let RenderMethod = "addImmOperands";
}

def disp5ep : Operand<i32>, ImmLeaf<i32, [{return isUInt<5>(Imm) && (Imm & 1) == 0;}]> {
  let PrintMethod = "printDisp5EP";
  let DecoderMethod = "decodeUImmOperand<5>";
  let ParserMatchClass = Imm5AsmOperand;
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

// Call target operand for CALL/TAIL instructions
def calltarget : Operand<i32> {
  let EncoderMethod = "getBranchTarget22OpValue";
  let DecoderMethod = "decodeBranchTarget22";
}

// 32-bit PC-relative branch target (bit 0 implicitly 0, V850E2+)
def brtarget32 : Operand<OtherVT> {
  let EncoderMethod = "getBranchTarget32OpValue";
  let DecoderMethod = "decodeBranchTarget32";
}

// AsmOperandClass for condition codes
def CondCodeAsmOperand : AsmOperandClass {
  let Name = "Condcode";
  let RenderMethod = "addCondcodeOperands";
}

// Condition code operand for SETF instruction
def condcode : Operand<i32> {
  let PrintMethod = "printCondCode";
  let ParserMatchClass = CondCodeAsmOperand;
}

// AsmOperandClass for cmov condition codes
def CmovCondAsmOperand : AsmOperandClass {
  let Name = "Cmov_cond";
  let RenderMethod = "addCmov_condOperands";
}

// Condition code operand for CMOV instruction
def cmov_cond : Operand<i32> {
  let PrintMethod = "printCondCode";
  let ParserMatchClass = CmovCondAsmOperand;
}

//===----------------------------------------------------------------------===//
// Predicates for CPU variants
//===----------------------------------------------------------------------===//

def HasV850E1 : Predicate<"Subtarget->hasV850E1()">,
                AssemblerPredicate<(all_of FeatureV850E1), "V850E1">;
def HasV850E2 : Predicate<"Subtarget->hasV850E2()">,
                AssemblerPredicate<(all_of FeatureV850E2), "V850E2">;
def HasV850E2M : Predicate<"Subtarget->hasV850E2M()">,
                 AssemblerPredicate<(all_of FeatureV850E2M), "V850E2M">;
def HasV850FPU : Predicate<"Subtarget->hasV850FPU()">,
                 AssemblerPredicate<(all_of FeatureV850FPU), "V850FPU">;
def HasV850E3 : Predicate<"Subtarget->hasV850E3()">,
                AssemblerPredicate<(all_of FeatureV850E3), "V850E3">;

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

def V850Tail     : SDNode<"V850ISD::TAIL", SDT_V850Call,
                          [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

def V850RetGlue  : SDNode<"V850ISD::RET_GLUE", SDTNone,
                          [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

def V850Wrapper  : SDNode<"V850ISD::WRAPPER", SDTIntUnaryOp>;

// Compare node - produces PSW flags
def SDT_V850Cmp : SDTypeProfile<0, 2, [SDTCisSameAs<0, 1>]>;
def V850Cmp     : SDNode<"V850ISD::CMP", SDT_V850Cmp, [SDNPOutGlue]>;

// Branch on condition code
def SDT_V850BrCC : SDTypeProfile<0, 2, [SDTCisVT<0, OtherVT>,
                                        SDTCisVT<1, i32>]>;
def V850BrCC    : SDNode<"V850ISD::BR_CC", SDT_V850BrCC,
                          [SDNPHasChain, SDNPInGlue]>;

// Select with condition code
def SDT_V850SelectCC : SDTypeProfile<1, 3, [SDTCisSameAs<0, 1>,
                                            SDTCisSameAs<1, 2>,
                                            SDTCisVT<3, i32>]>;
def V850SelectCC : SDNode<"V850ISD::SELECT_CC", SDT_V850SelectCC,
                           [SDNPInGlue]>;

// Multiply node - returns (low, high) pair
// SDTypeProfile<2 results, 2 operands, [constraints]>
def SDT_V850Mul : SDTypeProfile<2, 2, [SDTCisSameAs<0, 1>,
                                        SDTCisSameAs<0, 2>,
                                        SDTCisSameAs<0, 3>,
                                        SDTCisVT<0, i32>]>;
def V850smul : SDNode<"V850ISD::SMUL", SDT_V850Mul>;
def V850umul : SDNode<"V850ISD::UMUL", SDT_V850Mul>;

// Multiply-accumulate node - takes 4 i32s (a, b, acc_lo, acc_hi), returns 2 i32s (res_lo, res_hi)
def SDT_V850Mac : SDTypeProfile<2, 4, [SDTCisSameAs<0, 1>,
                                        SDTCisSameAs<0, 2>,
                                        SDTCisSameAs<0, 3>,
                                        SDTCisSameAs<0, 4>,
                                        SDTCisSameAs<0, 5>,
                                        SDTCisVT<0, i32>]>;
def V850smac : SDNode<"V850ISD::SMAC", SDT_V850Mac>;
def V850umac : SDNode<"V850ISD::UMAC", SDT_V850Mac>;

// Divide-remainder node - returns (quotient, remainder) pair
def SDT_V850DivRem : SDTypeProfile<2, 2, [SDTCisSameAs<0, 1>,
                                          SDTCisSameAs<0, 2>,
                                          SDTCisSameAs<0, 3>,
                                          SDTCisVT<0, i32>]>;
def V850sdivrem : SDNode<"V850ISD::SDIVREM", SDT_V850DivRem>;
def V850udivrem : SDNode<"V850ISD::UDIVREM", SDT_V850DivRem>;

// Bit manipulation in memory - (chain, addr, bitnum) -> chain
def SDT_V850BitMem : SDTypeProfile<0, 2, [SDTCisVT<0, i32>, SDTCisVT<1, i32>]>;
def V850set1mem : SDNode<"V850ISD::SET1_MEM", SDT_V850BitMem,
                         [SDNPHasChain, SDNPMayLoad, SDNPMayStore,
                          SDNPMemOperand]>;
def V850clr1mem : SDNode<"V850ISD::CLR1_MEM", SDT_V850BitMem,
                         [SDNPHasChain, SDNPMayLoad, SDNPMayStore,
                          SDNPMemOperand]>;
def V850not1mem : SDNode<"V850ISD::NOT1_MEM", SDT_V850BitMem,
                         [SDNPHasChain, SDNPMayLoad, SDNPMayStore,
                          SDNPMemOperand]>;

// Bit test in memory - (chain, addr, bitnum) -> (result, chain)
// Returns 1 if bit was 0 (Z flag set), 0 otherwise
def SDT_V850TstMem : SDTypeProfile<1, 2, [SDTCisVT<0, i32>,
                                          SDTCisVT<1, i32>,
                                          SDTCisVT<2, i32>]>;
def V850tst1mem : SDNode<"V850ISD::TST1_MEM", SDT_V850TstMem,
                         [SDNPHasChain, SDNPMayLoad, SDNPMemOperand]>;

// Jump table branch - (chain, index, jumptable) -> chain
// Uses SWITCH instruction for table-driven branching (V850E1+)
def SDT_V850BrJT : SDTypeProfile<0, 2, [SDTCisVT<0, i32>, SDTCisVT<1, i32>]>;
def V850brjt : SDNode<"V850ISD::BR_JT", SDT_V850BrJT,
                      [SDNPHasChain]>;

//===----------------------------------------------------------------------===//
// Pattern fragments for instruction selection
//===----------------------------------------------------------------------===//

// Check if constant fits in 16-bit signed immediate
def simm16_pred : PatLeaf<(i32 imm), [{
  return isInt<16>(N->getSExtValue());
}]>;

// Check if constant is in the range (-32768 to 65535) for combined MOVHI+MOVEA
def imm32_pred : PatLeaf<(i32 imm), [{
  return !isInt<16>(N->getSExtValue());
}]>;

// Extract high 16 bits of a 32-bit constant, adjusted for sign extension of low part
// When low 16 bits would be sign-extended as negative, add 1 to high part
def HI16 : SDNodeXForm<imm, [{
  int64_t Val = N->getSExtValue();
  int32_t Lo = SignExtend32<16>(Val & 0xFFFF);
  int32_t Hi = (Val - Lo) >> 16;
  return CurDAG->getTargetConstant((uint32_t)(Hi & 0xFFFF), SDLoc(N), MVT::i32);
}]>;

// Extract low 16 bits of a 32-bit constant (as signed 16-bit value)
// Masked to 32 bits for proper unsigned representation
def LO16 : SDNodeXForm<imm, [{
  int64_t Val = N->getSExtValue();
  int32_t Lo = SignExtend32<16>(Val & 0xFFFF);
  return CurDAG->getTargetConstant((uint32_t)Lo, SDLoc(N), MVT::i32);
}]>;

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
// Flags: CY, OV, S, Z modified
let Constraints = "$rs = $reg2", Defs = [PSW] in
def ADD : FormatI<0b001110, (outs GPR:$reg2), (ins GPR:$rs, GPR:$reg1),
                  "add\t$reg1, $reg2",
                  [(set GPR:$reg2, (add GPR:$rs, GPR:$reg1))]>;

// SUB reg1, reg2 - Subtract reg1 from reg2, store in reg2
// Opcode: 001101 (0x0D)
// Flags: CY, OV, S, Z modified
let Constraints = "$rs = $reg2", Defs = [PSW] in
def SUB : FormatI<0b001101, (outs GPR:$reg2), (ins GPR:$rs, GPR:$reg1),
                  "sub\t$reg1, $reg2",
                  [(set GPR:$reg2, (sub GPR:$rs, GPR:$reg1))]>;

// SUBR reg1, reg2 - Subtract reg2 from reg1, store in reg2 (reverse subtract)
// Opcode: 001100 (0x0C)
// Flags: CY, OV, S, Z modified
let Constraints = "$rs = $reg2", Defs = [PSW] in
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
// Flags: OV=0, S, Z modified
let Defs = [PSW] in
def NOT : FormatI<0b000001, (outs GPR:$reg2), (ins GPR:$reg1),
                  "not\t$reg1, $reg2",
                  [(set GPR:$reg2, (not GPR:$reg1))]>;

// DIVH reg1, reg2 - Divide halfword (reg2/reg1 -> reg2)
// Opcode: 000010 (0x02)
// Flags: OV, S, Z modified
let Constraints = "$rs = $reg2", Defs = [PSW] in
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
// Flags: CY, OV, S, Z, SAT modified
let Constraints = "$rs = $reg2", Defs = [PSW] in
def SATSUBR : FormatI<0b000100, (outs GPR:$reg2), (ins GPR:$rs, GPR:$reg1),
                      "satsubr\t$reg1, $reg2",
                      []>;

// SATSUB reg1, reg2 - Saturated subtract
// Opcode: 000101 (0x05)
// Flags: CY, OV, S, Z, SAT modified
// Operation: reg2 = saturate(reg2 - reg1)
let Constraints = "$rs = $reg2", Defs = [PSW] in
def SATSUB : FormatI<0b000101, (outs GPR:$reg2), (ins GPR:$rs, GPR:$reg1),
                     "satsub\t$reg1, $reg2",
                     [(set GPR:$reg2, (ssubsat GPR:$rs, GPR:$reg1))]>;

// SATADD reg1, reg2 - Saturated add
// Opcode: 000110 (0x06)
// Flags: CY, OV, S, Z, SAT modified
let Constraints = "$rs = $reg2", Defs = [PSW] in
def SATADD : FormatI<0b000110, (outs GPR:$reg2), (ins GPR:$rs, GPR:$reg1),
                     "satadd\t$reg1, $reg2",
                     [(set GPR:$reg2, (saddsat GPR:$rs, GPR:$reg1))]>;

// MULH reg1, reg2 - Multiply halfword (16x16 -> 32)
// Opcode: 000111 (0x07)
let Constraints = "$rs = $reg2" in
def MULH : FormatI<0b000111, (outs GPR:$reg2), (ins GPR:$rs, GPR:$reg1),
                   "mulh\t$reg1, $reg2",
                   []>;

// OR reg1, reg2 - Bitwise OR
// Opcode: 001000 (0x08)
// Flags: OV=0, S, Z modified
let Constraints = "$rs = $reg2", Defs = [PSW] in
def OR : FormatI<0b001000, (outs GPR:$reg2), (ins GPR:$rs, GPR:$reg1),
                 "or\t$reg1, $reg2",
                 [(set GPR:$reg2, (or GPR:$rs, GPR:$reg1))]>;

// XOR reg1, reg2 - Bitwise XOR
// Opcode: 001001 (0x09)
// Flags: OV=0, S, Z modified
let Constraints = "$rs = $reg2", Defs = [PSW] in
def XOR : FormatI<0b001001, (outs GPR:$reg2), (ins GPR:$rs, GPR:$reg1),
                  "xor\t$reg1, $reg2",
                  [(set GPR:$reg2, (xor GPR:$rs, GPR:$reg1))]>;

// AND reg1, reg2 - Bitwise AND
// Opcode: 001010 (0x0A)
// Flags: OV=0, S, Z modified
let Constraints = "$rs = $reg2", Defs = [PSW] in
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
// Flags: CY, OV, S, Z, SAT modified
// Operation: reg2 = saturate(reg2 + imm5)
let Constraints = "$rs = $reg2", Defs = [PSW] in
def SATADDi : FormatII<0b010001, (outs GPR:$reg2), (ins GPR:$rs, simm5:$imm5),
                       "satadd\t$imm5, $reg2",
                       [(set GPR:$reg2, (saddsat GPR:$rs, simm5:$imm5))]>;

// ADD imm5, reg2 - Add sign-extended 5-bit immediate to reg2
// Opcode: 010010 (0x12)
// Flags: CY, OV, S, Z modified
let Constraints = "$rs = $reg2", Defs = [PSW] in
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
// Flags: CY, OV=0, S, Z modified
let Constraints = "$rs = $reg2", Defs = [PSW] in
def SHRi : FormatII<0b010100, (outs GPR:$reg2), (ins GPR:$rs, uimm5:$imm5),
                    "shr\t$imm5, $reg2",
                    [(set GPR:$reg2, (srl GPR:$rs, uimm5:$imm5))]>;

// SAR imm5, reg2 - Shift right arithmetic by immediate
// Opcode: 010101 (0x15)
// Flags: CY, OV=0, S, Z modified
let Constraints = "$rs = $reg2", Defs = [PSW] in
def SARi : FormatII<0b010101, (outs GPR:$reg2), (ins GPR:$rs, uimm5:$imm5),
                    "sar\t$imm5, $reg2",
                    [(set GPR:$reg2, (sra GPR:$rs, uimm5:$imm5))]>;

// SHL imm5, reg2 - Shift left logical by immediate
// Opcode: 010110 (0x16)
// Flags: CY, OV=0, S, Z modified
let Constraints = "$rs = $reg2", Defs = [PSW] in
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
// Flags: CY, OV, S, Z modified
let Defs = [PSW] in
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

//===----------------------------------------------------------------------===//
// Patterns for constant materialization
//===----------------------------------------------------------------------===//

// 16-bit signed constant: movea imm16, r0, rd
def : Pat<(i32 simm16_pred:$imm), (MOVEA R0, simm16:$imm)>;

// SATSUBI imm16, reg1, reg2 - Saturated subtract immediate
// Opcode: 110011 (0x33)
// Flags: CY, OV, S, Z, SAT modified
// Operation: reg2 = saturate(reg1 - imm16)
let Defs = [PSW] in
def SATSUBI : FormatVI<0b110011, (outs GPR:$reg2), (ins GPR:$reg1, simm16:$imm16),
                       "satsubi\t$imm16, $reg1, $reg2",
                       [(set GPR:$reg2, (ssubsat GPR:$reg1, simm16:$imm16))]>;

// ORI imm16, reg1, reg2 - OR with zero-extended immediate
// Opcode: 110100 (0x34)
// Flags: OV=0, S, Z modified
let Defs = [PSW] in
def ORI : FormatVI<0b110100, (outs GPR:$reg2), (ins GPR:$reg1, uimm16:$imm16),
                   "ori\t$imm16, $reg1, $reg2",
                   [(set GPR:$reg2, (or GPR:$reg1, uimm16:$imm16))]>;

// XORI imm16, reg1, reg2 - XOR with zero-extended immediate
// Opcode: 110101 (0x35)
// Flags: OV=0, S, Z modified
let Defs = [PSW] in
def XORI : FormatVI<0b110101, (outs GPR:$reg2), (ins GPR:$reg1, uimm16:$imm16),
                    "xori\t$imm16, $reg1, $reg2",
                    [(set GPR:$reg2, (xor GPR:$reg1, uimm16:$imm16))]>;

// ANDI imm16, reg1, reg2 - AND with zero-extended immediate
// Opcode: 110110 (0x36)
// Flags: OV=0, S, Z modified
let Defs = [PSW] in
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
let isCall = 1 in
def JARL : FormatV<0b101111, (outs GPR:$reg2), (ins brtarget22:$disp22),
                   "jarl\t$disp22, $reg2",
                   []>;

// CALL pseudo-instruction - expands to JARL with LP as link register
// Used for function calls in code generation
// Defs: LP (return address), R6-R11 (caller-saved)
// Uses: SP (stack pointer)
let isCall = 1,
    Defs = [LP, R6, R7, R8, R9, R10, R11],
    Uses = [SP] in
def CALL : V850Pseudo<(outs), (ins brtarget22:$target),
                      "jarl\t$target, lp",
                      []>;

// TAIL_CALL pseudo-instruction for tail call optimization
// Uses JR instead of JARL since we don't need to save return address
let isCall = 1, isTerminator = 1, isReturn = 1, isBarrier = 1,
    Uses = [SP] in
def TAIL_CALL : V850Pseudo<(outs), (ins calltarget:$target),
                           "jr\t$target",
                           [(V850Tail tglobaladdr:$target)]>;

// TAIL_CALL_REG - Tail call via register (indirect)
let isCall = 1, isTerminator = 1, isReturn = 1, isBarrier = 1, isIndirectBranch = 1,
    Uses = [SP] in
def TAIL_CALL_REG : V850Pseudo<(outs), (ins GPR:$target),
                               "jmp\t[$target]",
                               [(V850Tail GPR:$target)]>;

// Pattern for external symbols (e.g., external function tail calls)
def : Pat<(V850Tail texternalsym:$target), (TAIL_CALL texternalsym:$target)>;

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
// Flags: CY, OV=0, S, Z modified
let Constraints = "$rs = $reg2", Defs = [PSW] in
def SHR : FormatIX<0b111111, 0b000010, (outs GPR:$reg2), (ins GPR:$rs, GPR:$reg1),
                   "shr\t$reg1, $reg2",
                   [(set GPR:$reg2, (srl GPR:$rs, GPR:$reg1))]>;

// SAR reg1, reg2 - Shift right arithmetic by register
// Opcode: 111111 (0x3F), sub-op: 000100 (0x04)
// Flags: CY, OV=0, S, Z modified
let Constraints = "$rs = $reg2", Defs = [PSW] in
def SAR : FormatIX<0b111111, 0b000100, (outs GPR:$reg2), (ins GPR:$rs, GPR:$reg1),
                   "sar\t$reg1, $reg2",
                   [(set GPR:$reg2, (sra GPR:$rs, GPR:$reg1))]>;

// SHL reg1, reg2 - Shift left logical by register
// Opcode: 111111 (0x3F), sub-op: 000110
// Flags: CY, OV=0, S, Z modified
let Constraints = "$rs = $reg2", Defs = [PSW] in
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

//===----------------------------------------------------------------------===//
// Bit Manipulation Instructions - Format IX (32-bit, register variant)
// These use reg2[2:0] to specify the bit number dynamically
// Encoding: rrrrr111111RRRRR 00000000111000vv (vv = variant)
//===----------------------------------------------------------------------===//

// SET1 reg2, [reg1] - Set bit in memory (bit number from reg2[2:0])
// Opcode: 111111, sub-op: 000111, variant bits[18:17]: 00
let mayLoad = 1, mayStore = 1 in
def SET1r : FormatIX<0b111111, 0b000111, (outs),
                     (ins GPR:$reg2, GPR:$reg1),
                     "set1\t$reg2, [$reg1]",
                     []>,
            Requires<[HasV850E1]> {
  let Inst{18-17} = 0b00;
}

// NOT1 reg2, [reg1] - Toggle bit in memory (bit number from reg2[2:0])
// Opcode: 111111, sub-op: 000111, variant bits[18:17]: 01
let mayLoad = 1, mayStore = 1 in
def NOT1r : FormatIX<0b111111, 0b000111, (outs),
                     (ins GPR:$reg2, GPR:$reg1),
                     "not1\t$reg2, [$reg1]",
                     []>,
            Requires<[HasV850E1]> {
  let Inst{18-17} = 0b01;
}

// CLR1 reg2, [reg1] - Clear bit in memory (bit number from reg2[2:0])
// Opcode: 111111, sub-op: 000111, variant bits[18:17]: 10
let mayLoad = 1, mayStore = 1 in
def CLR1r : FormatIX<0b111111, 0b000111, (outs),
                     (ins GPR:$reg2, GPR:$reg1),
                     "clr1\t$reg2, [$reg1]",
                     []>,
            Requires<[HasV850E1]> {
  let Inst{18-17} = 0b10;
}

// TST1 reg2, [reg1] - Test bit in memory (bit number from reg2[2:0])
// Opcode: 111111, sub-op: 000111, variant bits[18:17]: 11
let mayLoad = 1, Defs = [PSW] in
def TST1r : FormatIX<0b111111, 0b000111, (outs),
                     (ins GPR:$reg2, GPR:$reg1),
                     "tst1\t$reg2, [$reg1]",
                     []>,
            Requires<[HasV850E1]> {
  let Inst{18-17} = 0b11;
}

//===----------------------------------------------------------------------===//
// Additional Patterns
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Atomic Bit Manipulation Intrinsic Patterns (V850E1+)
// These map the llvm.v850.set1/clr1/not1/tst1 intrinsics to instructions
//===----------------------------------------------------------------------===//

let Predicates = [HasV850E1] in {
// SET1 - Atomically set a bit in memory
def : Pat<(int_v850_set1 GPR:$addr, GPR:$bit),
          (SET1r GPR:$bit, GPR:$addr)>;

// CLR1 - Atomically clear a bit in memory
def : Pat<(int_v850_clr1 GPR:$addr, GPR:$bit),
          (CLR1r GPR:$bit, GPR:$addr)>;

// NOT1 - Atomically toggle a bit in memory
def : Pat<(int_v850_not1 GPR:$addr, GPR:$bit),
          (NOT1r GPR:$bit, GPR:$addr)>;
}

// TST1_PSEUDO - Test bit in memory and return result
// Expands to TST1r + SETF z (condition code 2 = Z flag)
let usesCustomInserter = 1, Predicates = [HasV850E1] in
def TST1_PSEUDO : V850Pseudo<(outs GPR:$result), (ins GPR:$bit, GPR:$addr),
                             "# TST1_PSEUDO $bit, [$addr] -> $result",
                             [(set GPR:$result, (V850tst1mem GPR:$addr, GPR:$bit))]>;

//===----------------------------------------------------------------------===//
// Large constant materialization patterns
//===----------------------------------------------------------------------===//

// 32-bit constant requires MOVHI + MOVEA sequence
// For a 32-bit value V = (Hi << 16) + Lo (signed)
// We need to account for sign extension of Lo
def : Pat<(i32 imm32_pred:$imm),
          (MOVEA (MOVHI R0, (HI16 $imm)), (LO16 $imm))>;

//===----------------------------------------------------------------------===//
// Load patterns
//===----------------------------------------------------------------------===//

// Simple register + 0 offset patterns
def : Pat<(i32 (load GPR:$base)), (LDW GPR:$base, 0)>;
def : Pat<(i32 (sextloadi8 GPR:$base)), (LDB GPR:$base, 0)>;
def : Pat<(i32 (sextloadi16 GPR:$base)), (LDH GPR:$base, 0)>;
def : Pat<(i32 (extloadi8 GPR:$base)), (LDB GPR:$base, 0)>;
def : Pat<(i32 (extloadi16 GPR:$base)), (LDH GPR:$base, 0)>;

// Register + signed 16-bit offset patterns
def : Pat<(i32 (load (add GPR:$base, simm16:$off))), (LDW GPR:$base, simm16:$off)>;
def : Pat<(i32 (sextloadi8 (add GPR:$base, simm16:$off))), (LDB GPR:$base, simm16:$off)>;
def : Pat<(i32 (sextloadi16 (add GPR:$base, simm16:$off))), (LDH GPR:$base, simm16:$off)>;
def : Pat<(i32 (extloadi8 (add GPR:$base, simm16:$off))), (LDB GPR:$base, simm16:$off)>;
def : Pat<(i32 (extloadi16 (add GPR:$base, simm16:$off))), (LDH GPR:$base, simm16:$off)>;

// Zero-extending loads need AND with mask (base V850 has no LD.BU/LD.HU)
def : Pat<(i32 (zextloadi8 GPR:$base)), (ANDI (LDB GPR:$base, 0), 0xFF)>;
def : Pat<(i32 (zextloadi16 GPR:$base)), (ANDI (LDH GPR:$base, 0), 0xFFFF)>;
def : Pat<(i32 (zextloadi8 (add GPR:$base, simm16:$off))),
          (ANDI (LDB GPR:$base, simm16:$off), 0xFF)>;
def : Pat<(i32 (zextloadi16 (add GPR:$base, simm16:$off))),
          (ANDI (LDH GPR:$base, simm16:$off), 0xFFFF)>;

//===----------------------------------------------------------------------===//
// Store patterns
//===----------------------------------------------------------------------===//

// Simple register + 0 offset patterns
def : Pat<(store GPR:$src, GPR:$base), (STW GPR:$src, GPR:$base, 0)>;
def : Pat<(truncstorei8 GPR:$src, GPR:$base), (STB GPR:$src, GPR:$base, 0)>;
def : Pat<(truncstorei16 GPR:$src, GPR:$base), (STH GPR:$src, GPR:$base, 0)>;

// Register + signed 16-bit offset patterns
def : Pat<(store GPR:$src, (add GPR:$base, simm16:$off)), (STW GPR:$src, GPR:$base, simm16:$off)>;
def : Pat<(truncstorei8 GPR:$src, (add GPR:$base, simm16:$off)), (STB GPR:$src, GPR:$base, simm16:$off)>;
def : Pat<(truncstorei16 GPR:$src, (add GPR:$base, simm16:$off)), (STH GPR:$src, GPR:$base, simm16:$off)>;

//===----------------------------------------------------------------------===//
// V850E1 Instructions (require HasV850E1 predicate)
//===----------------------------------------------------------------------===//

let Predicates = [HasV850E1] in {

//===----------------------------------------------------------------------===//
// Sign/Zero Extension Instructions (16-bit)
// Format I variant with reg2 = 0
//===----------------------------------------------------------------------===//

// SXB reg1 - Sign extend byte
// Opcode: 000101 with reg2 = 0
def SXB : FormatI<0b000101, (outs GPR:$reg1), (ins GPR:$rs),
                  "sxb\t$reg1",
                  [(set GPR:$reg1, (sext_inreg GPR:$rs, i8))]> {
  let reg2 = 0;
  let Constraints = "$rs = $reg1";
}

// SXH reg1 - Sign extend halfword
// Opcode: 000111 with reg2 = 0
def SXH : FormatI<0b000111, (outs GPR:$reg1), (ins GPR:$rs),
                  "sxh\t$reg1",
                  [(set GPR:$reg1, (sext_inreg GPR:$rs, i16))]> {
  let reg2 = 0;
  let Constraints = "$rs = $reg1";
}

// ZXB reg1 - Zero extend byte
// Opcode: 000100 with reg2 = 0
def ZXB : FormatI<0b000100, (outs GPR:$reg1), (ins GPR:$rs),
                  "zxb\t$reg1",
                  [(set GPR:$reg1, (and GPR:$rs, 0xFF))]> {
  let reg2 = 0;
  let Constraints = "$rs = $reg1";
}

// ZXH reg1 - Zero extend halfword
// Opcode: 000110 with reg2 = 0
def ZXH : FormatI<0b000110, (outs GPR:$reg1), (ins GPR:$rs),
                  "zxh\t$reg1",
                  [(set GPR:$reg1, (and GPR:$rs, 0xFFFF))]> {
  let reg2 = 0;
  let Constraints = "$rs = $reg1";
}

// SWITCH reg1 - Jump with table look up
// Opcode: 000010 with reg2 = 0
let isBranch = 1, isTerminator = 1, isBarrier = 1, isIndirectBranch = 1 in
def SWITCH : FormatI<0b000010, (outs), (ins GPR:$reg1),
                     "switch\t$reg1",
                     []> {
  let reg2 = 0;
}

// SWITCH_JT - Pseudo instruction for jump table branch
// Expands to SWITCH + inline jump table data
// The jump table contains signed 16-bit offsets from the table base
let isBranch = 1, isTerminator = 1, isBarrier = 1, isIndirectBranch = 1,
    isCodeGenOnly = 1 in
def SWITCH_JT : V850Pseudo<(outs), (ins GPR:$index, i32imm:$jti),
                           "switch_jt\t$index, $jti",
                           [(V850brjt GPR:$index, tjumptable:$jti)]>,
                Requires<[HasV850E1]>;

//===----------------------------------------------------------------------===//
// Short Load/Store Instructions - Format IV (16-bit)
//===----------------------------------------------------------------------===//

// SLD.BU disp4[ep], reg2 - Short load byte unsigned (zero-extended)
// Uses EP as base, 4-bit displacement (0-15 bytes)
// Opcode: 0000110
let mayLoad = 1, Uses = [EP] in
def SLDBU : FormatIV_E1<0b0000110, (outs GPR:$reg2), (ins disp4ep:$disp4),
                        "sld.bu\t$disp4, $reg2",
                        []>;

// SLD.HU disp5[ep], reg2 - Short load halfword unsigned (zero-extended)
// Uses EP as base, 5-bit displacement (0-30 bytes, halfword aligned)
// The 4-bit field encodes disp/2 (halfword index), so byte offset = disp4 * 2
// Opcode: 0000111
let mayLoad = 1, Uses = [EP] in
def SLDHU : FormatIV_E1<0b0000111, (outs GPR:$reg2), (ins disp5ep:$disp5),
                        "sld.hu\t$disp5, $reg2",
                        []> {
  bits<5> disp5;
  let disp4 = disp5{4-1};  // Encode disp5[4:1], bit 0 is always 0
}

//===----------------------------------------------------------------------===//
// SASF Instruction
//===----------------------------------------------------------------------===//

// SASF cccc, reg2 - Shift and set flag condition
// Shifts reg2 left by 1, sets bit 0 based on condition code
// Opcode: 111111, sub-op: 001000
let Constraints = "$rs = $reg2", Uses = [PSW] in
def SASF : FormatIX<0b111111, 0b001000, (outs GPR:$reg2),
                    (ins GPR:$rs, condcode:$cond),
                    "sasf\t$cond, $reg2",
                    []> {
  bits<5> cond;
  let reg1 = cond;
}

//===----------------------------------------------------------------------===//
// Unsigned Load Instructions (32-bit) - Format VII variant
//===----------------------------------------------------------------------===//

// LD.BU disp16[reg1], reg2 - Load byte unsigned (zero-extended)
// Opcode: 111100 (0x3C) with special bit encoding
let mayLoad = 1 in
def LDBU : FormatVII<0b111100, (outs GPR:$reg2), (ins GPR:$reg1, simm16:$disp16),
                     "ld.bu\t$disp16[$reg1], $reg2",
                     [(set GPR:$reg2, (zextloadi8 (add GPR:$reg1, simm16:$disp16)))]>;

// LD.HU disp16[reg1], reg2 - Load halfword unsigned (zero-extended)
// Opcode: 111111 (0x3F) with sub-opcode
let mayLoad = 1 in
def LDHU : FormatVII<0b111111, (outs GPR:$reg2), (ins GPR:$reg1, simm16:$disp16),
                     "ld.hu\t$disp16[$reg1], $reg2",
                     [(set GPR:$reg2, (zextloadi16 (add GPR:$reg1, simm16:$disp16)))]>;

// Patterns for zero-extending loads with base + 0 offset using LD.BU/LD.HU
def : Pat<(i32 (zextloadi8 GPR:$base)), (LDBU GPR:$base, 0)>;
def : Pat<(i32 (zextloadi16 GPR:$base)), (LDHU GPR:$base, 0)>;

//===----------------------------------------------------------------------===//
// Multiply Instructions (32-bit) - Format XI
//===----------------------------------------------------------------------===//

// MUL reg1, reg2, reg3 - Multiply word (32x32 -> 64)
// reg2 (input/output): multiplicand, receives low 32 bits of result
// reg3 (output): receives high 32 bits of result
// Opcode: 111111, sub-op: 010001, sub-id: 00010
def MUL : FormatXI<0b111111, 0b010001, 0b00010, (outs GPR:$reg2, GPR:$reg3),
                   (ins GPR:$rs, GPR:$reg1),
                   "mul\t$reg1, $reg2, $reg3",
                   [(set GPR:$reg2, GPR:$reg3, (V850smul GPR:$rs, GPR:$reg1))]>,
          Requires<[HasV850E1]> {
  let Constraints = "$rs = $reg2";
}

// MULU reg1, reg2, reg3 - Multiply word unsigned (32x32 -> 64)
// reg2 (input/output): multiplicand, receives low 32 bits of result
// reg3 (output): receives high 32 bits of result
// Opcode: 111111, sub-op: 010001, sub-id: 00100
def MULU : FormatXI<0b111111, 0b010001, 0b00100, (outs GPR:$reg2, GPR:$reg3),
                    (ins GPR:$rs, GPR:$reg1),
                    "mulu\t$reg1, $reg2, $reg3",
                    [(set GPR:$reg2, GPR:$reg3, (V850umul GPR:$rs, GPR:$reg1))]>,
          Requires<[HasV850E1]> {
  let Constraints = "$rs = $reg2";
}

// MUL imm9, reg2, reg3 - Multiply with signed 9-bit immediate
// reg2 (input/output): multiplicand, receives low 32 bits of result
// reg3 (output): receives high 32 bits of result
// Opcode: 111111, sub-op: 010010
def MULi : FormatXI_IMM9<0b111111, 0b010010, (outs GPR:$reg2, GPR:$reg3),
                         (ins GPR:$rs, simm9:$imm9),
                         "mul\t$imm9, $reg2, $reg3",
                         []>,
           Requires<[HasV850E1]> {
  let Constraints = "$rs = $reg2";
}

// MULU imm9, reg2, reg3 - Multiply with unsigned 9-bit immediate
// reg2 (input/output): multiplicand, receives low 32 bits of result
// reg3 (output): receives high 32 bits of result
// Opcode: 111111, sub-op: 010010
def MULUi : FormatXI_IMM9<0b111111, 0b010010, (outs GPR:$reg2, GPR:$reg3),
                          (ins GPR:$rs, uimm9:$imm9),
                          "mulu\t$imm9, $reg2, $reg3",
                          []>,
            Requires<[HasV850E1]> {
  let Constraints = "$rs = $reg2";
  let Inst{16} = 1;  // Unsigned flag
}

//===----------------------------------------------------------------------===//
// Divide Instructions (32-bit) - Format XI
//===----------------------------------------------------------------------===//

// DIV reg1, reg2, reg3 - Divide word signed
// reg2 (input/output): dividend, receives quotient
// reg3 (output): receives remainder
// Opcode: 111111, sub-op: 010100, sub-id: 00010
// Flags: OV, S, Z modified
let Defs = [PSW] in
def DIV : FormatXI<0b111111, 0b010100, 0b00010, (outs GPR:$reg2, GPR:$reg3),
                   (ins GPR:$rs, GPR:$reg1),
                   "div\t$reg1, $reg2, $reg3",
                   [(set GPR:$reg2, GPR:$reg3, (V850sdivrem GPR:$rs, GPR:$reg1))]>,
          Requires<[HasV850E1]> {
  let Constraints = "$rs = $reg2";
}

// DIVU reg1, reg2, reg3 - Divide word unsigned
// reg2 (input/output): dividend, receives quotient
// reg3 (output): receives remainder
// Opcode: 111111, sub-op: 010110, sub-id: 00010
// Flags: OV, S, Z modified
let Defs = [PSW] in
def DIVU : FormatXI<0b111111, 0b010110, 0b00010, (outs GPR:$reg2, GPR:$reg3),
                    (ins GPR:$rs, GPR:$reg1),
                    "divu\t$reg1, $reg2, $reg3",
                    [(set GPR:$reg2, GPR:$reg3, (V850udivrem GPR:$rs, GPR:$reg1))]>,
          Requires<[HasV850E1]> {
  let Constraints = "$rs = $reg2";
}

// DIVHU reg1, reg2, reg3 - Divide halfword unsigned
// Opcode: 111111, sub-op: 010101, sub-id: 00010
// Flags: OV, S, Z modified
let Defs = [PSW] in
def DIVHU : FormatXI<0b111111, 0b010101, 0b00010, (outs GPR:$reg2, GPR:$reg3),
                     (ins GPR:$rs, GPR:$reg1),
                     "divhu\t$reg1, $reg2, $reg3",
                     []> {
  let Constraints = "$rs = $reg2";
}

// DIVH reg1, reg2, reg3 - Divide halfword signed (3-operand form)
// reg2 (input/output): dividend, receives quotient
// reg3 (output): receives remainder
// Opcode: 111111, sub-op: 010100, sub-id: 00000
// Flags: OV, S, Z modified
let Defs = [PSW] in
def DIVH_3 : FormatXI<0b111111, 0b010100, 0b00000, (outs GPR:$reg2, GPR:$reg3),
                      (ins GPR:$rs, GPR:$reg1),
                      "divh\t$reg1, $reg2, $reg3",
                      []>,
             Requires<[HasV850E1]> {
  let Constraints = "$rs = $reg2";
}

// DIVQ/DIVQU - High-speed divide instructions (V850E2M only)
// These use variable-step execution and are faster than DIV/DIVU
let Predicates = [HasV850E2M] in {

// DIVQ reg1, reg2, reg3 - Divide word signed quickly (V850E2M)
// High-speed division with variable-step execution (N+5 cycles)
// reg2 (input/output): dividend, receives quotient
// reg3 (output): receives remainder
// Opcode: 111111, sub-op: 010111, sub-id: 11100
// Flags: OV, S, Z modified
// AddedComplexity makes DIVQ preferred over DIV on V850E2M (faster)
let Defs = [PSW], AddedComplexity = 10 in
def DIVQ : FormatXI<0b111111, 0b010111, 0b11100, (outs GPR:$reg2, GPR:$reg3),
                    (ins GPR:$rs, GPR:$reg1),
                    "divq\t$reg1, $reg2, $reg3",
                    [(set GPR:$reg2, GPR:$reg3, (V850sdivrem GPR:$rs, GPR:$reg1))]> {
  let Constraints = "$rs = $reg2";
}

// DIVQU reg1, reg2, reg3 - Divide word unsigned quickly (V850E2M)
// High-speed division with variable-step execution (N+4 cycles)
// reg2 (input/output): dividend, receives quotient
// reg3 (output): receives remainder
// Opcode: 111111, sub-op: 010111, sub-id: 11110
// Flags: OV, S, Z modified
// AddedComplexity makes DIVQU preferred over DIVU on V850E2M (faster)
let Defs = [PSW], AddedComplexity = 10 in
def DIVQU : FormatXI<0b111111, 0b010111, 0b11110, (outs GPR:$reg2, GPR:$reg3),
                    (ins GPR:$rs, GPR:$reg1),
                    "divqu\t$reg1, $reg2, $reg3",
                    [(set GPR:$reg2, GPR:$reg3, (V850udivrem GPR:$rs, GPR:$reg1))]> {
  let Constraints = "$rs = $reg2";
}

} // Predicates = [HasV850E2M]

//===----------------------------------------------------------------------===//
// PREPARE/DISPOSE Instructions (Format XIII)
// Used for function prologue/epilogue optimization
//===----------------------------------------------------------------------===//

// PREPARE list12, imm5 - Push registers and allocate stack frame
// list12 is a 12-bit mask for registers r20-r31 (EP=r30, LP=r31)
// imm5 is multiplied by 4 to get additional stack allocation
// Note: Full register list parsing requires custom assembly parser support
// For now, list12 and imm5 are specified as raw immediate operands
// Note: PREPARE and DISPOSE share the same encoding (opcode 11001 with reg1=0).
// PREPARE is used for disassembly; DISPOSE is encoding-only.
let Defs = [SP], Uses = [SP], mayStore = 1 in
def PREPARE : FormatXIII<0b11001, (outs), (ins uimm12:$list12, uimm5:$imm5),
                         "prepare\t$list12, $imm5",
                         []> {
  let reg1 = 0;  // No jump register for basic PREPARE
}

// DISPOSE imm5, list12 - Deallocate stack frame and pop registers
// Reverse of PREPARE - same encoding as PREPARE, but different semantics
// Marked as isCodeGenOnly to avoid disassembly conflict with PREPARE
let Defs = [SP], Uses = [SP], mayLoad = 1, isCodeGenOnly = 1 in
def DISPOSE : FormatXIII<0b11001, (outs), (ins uimm5:$imm5, uimm12:$list12),
                         "dispose\t$imm5, $list12",
                         []> {
  let reg1 = 0;  // No jump for basic DISPOSE
}

// DISPOSE imm5, list12, [reg1] - Dispose with indirect jump
// Jumps to address in reg1 after restoring registers
// This has a different encoding (reg1 != 0), so it's unique
let Defs = [SP], Uses = [SP], mayLoad = 1, isReturn = 1, isTerminator = 1, isBarrier = 1 in
def DISPOSEr : FormatXIII<0b11001, (outs), (ins uimm5:$imm5, uimm12:$list12, GPR:$reg1),
                          "dispose\t$imm5, $list12, [$reg1]",
                          []>;

//===----------------------------------------------------------------------===//
// Byte Swap Instructions (32-bit) - Format XII
// Encoding: rrrrr11111100000 wwwww011010cccc0
// These use Format XII with imm5=0 and cond field for variant
//===----------------------------------------------------------------------===//

// BSW reg2, reg3 - Byte swap word
// Opcode: 111111, sub-op: 011010, cond: 0000
let Defs = [PSW] in
def BSW : FormatXII<0b111111, 0b011010, (outs GPR:$reg3), (ins GPR:$reg2),
                    "bsw\t$reg2, $reg3",
                    [(set GPR:$reg3, (bswap GPR:$reg2))]> {
  let imm5 = 0;
  let cond = 0b0000;
}

// BSH reg2, reg3 - Byte swap halfword
// Opcode: 111111, sub-op: 011010, cond: 0001
let Defs = [PSW] in
def BSH : FormatXII<0b111111, 0b011010, (outs GPR:$reg3), (ins GPR:$reg2),
                    "bsh\t$reg2, $reg3",
                    []> {
  let imm5 = 0;
  let cond = 0b0001;
}

// HSW reg2, reg3 - Halfword swap word
// Opcode: 111111, sub-op: 011010, cond: 0010
let Defs = [PSW] in
def HSW : FormatXII<0b111111, 0b011010, (outs GPR:$reg3), (ins GPR:$reg2),
                    "hsw\t$reg2, $reg3",
                    [(set GPR:$reg3, (rotr GPR:$reg2, (i32 16)))]> {
  let imm5 = 0;
  let cond = 0b0010;
}

// HSW patterns for expanded rotate by 16 (since ROTR is Expand)
def : Pat<(or (shl GPR:$rs, (i32 16)), (srl GPR:$rs, (i32 16))), (HSW GPR:$rs)>;
def : Pat<(or (srl GPR:$rs, (i32 16)), (shl GPR:$rs, (i32 16))), (HSW GPR:$rs)>;

// BSH pattern: for bswap16 with masked input
// When upper 16 bits are known zero, bsh is more efficient than bsw + shr
// Pattern: (srl (bswap (and x, 0xFFFF)), 16) -> bsh x
def : Pat<(srl (bswap (and GPR:$src, 0xFFFF)), (i32 16)), (BSH GPR:$src)>;

// Intrinsic patterns for HSW and BSH
def : Pat<(int_v850_hsw GPR:$src), (HSW GPR:$src)>;
def : Pat<(int_v850_bsh GPR:$src), (BSH GPR:$src)>;

//===----------------------------------------------------------------------===//
// Conditional Move Instructions (32-bit) - Format XI/XII
//===----------------------------------------------------------------------===//

// CMOV cccc, reg1, reg2, reg3 - Conditional move (register form)
// If condition true: reg3 = reg1, else reg3 = reg2
// Opcode: 111111, sub-op: 011001, subid: {cond, 0}
let Uses = [PSW] in
def CMOVr : FormatXI<0b111111, 0b011001, 0b00000, (outs GPR:$reg3),
                     (ins cmov_cond:$cond, GPR:$reg1, GPR:$reg2),
                     "cmov\t$cond, $reg1, $reg2, $reg3",
                     []> {
  bits<4> cond;
  let Inst{20-17} = cond;
  let Inst{16} = 0;
}

// CMOV cccc, imm5, reg2, reg3 - Conditional move (immediate form)
// If condition true: reg3 = sign_ext(imm5), else reg3 = reg2
// Opcode: 111111, sub-op: 011000
let Uses = [PSW] in
def CMOVi : FormatXII<0b111111, 0b011000, (outs GPR:$reg3),
                      (ins cmov_cond:$cond, simm5:$imm5, GPR:$reg2),
                      "cmov\t$cond, $imm5, $reg2, $reg3",
                      []>;

//===----------------------------------------------------------------------===//
// CALLT/CTRET Instructions
//===----------------------------------------------------------------------===//

// CALLT imm6 - Call with table look up
// Format II variant with 5-bit opcode (01000) and 6-bit immediate
let isCall = 1, Defs = [CTPC, CTPSW] in
def CALLT : FormatII_IMM6<0b01000, (outs), (ins uimm6:$imm6),
                          "callt\t$imm6",
                          []>;

// CTRET - Return from CALLT
// Opcode: 111111 (0x3F), sub-op: 010001, vector: 00100
let isReturn = 1, isTerminator = 1, isBarrier = 1, Uses = [CTPC, CTPSW] in
def CTRET : FormatX<0b111111, 0b010001, (outs), (ins),
                    "ctret",
                    []> {
  let vector = 0b00100;
}

// DBTRAP - Debug trap
// Opcode: 1111100001000000 (16-bit)
let hasSideEffects = 1, Defs = [DBPC, DBPSW] in
def DBTRAP : V850Inst16<(outs), (ins),
                        "dbtrap",
                        []> {
  let Inst{15-0} = 0b1111100001000000;
}

// DBRET - Return from debug trap
// Opcode: 111111 (0x3F), sub-op: 010001, vector: 00110
let isReturn = 1, isTerminator = 1, isBarrier = 1,
    hasSideEffects = 1, Uses = [DBPC, DBPSW] in
def DBRET : FormatX<0b111111, 0b010001, (outs), (ins),
                    "dbret",
                    []> {
  let vector = 0b00110;
}

} // Predicates = [HasV850E1]

//===----------------------------------------------------------------------===//
// V850E2 Instructions (require HasV850E2 predicate)
//===----------------------------------------------------------------------===//

let Predicates = [HasV850E2] in {

// ADF cccc, reg1, reg2, reg3 - Add on condition flag
// If condition true: reg3 = reg2 + reg1 + CY, else reg3 = reg2 + CY
// Opcode: 111111, sub-op: 011101, subid: {cond, 0}
let Uses = [PSW] in
def ADF : FormatXI<0b111111, 0b011101, 0b00000, (outs GPR:$reg3),
                   (ins cmov_cond:$cond, GPR:$reg1, GPR:$reg2),
                   "adf\t$cond, $reg1, $reg2, $reg3",
                   []> {
  bits<4> cond;
  let Inst{20-17} = cond;
  let Inst{16} = 0;
}

// SBF cccc, reg1, reg2, reg3 - Subtract on condition flag
// If condition true: reg3 = reg2 - reg1 - CY, else reg3 = reg2 - CY
// Opcode: 111111, sub-op: 011100, subid: {cond, 0}
let Uses = [PSW] in
def SBF : FormatXI<0b111111, 0b011100, 0b00000, (outs GPR:$reg3),
                   (ins cmov_cond:$cond, GPR:$reg1, GPR:$reg2),
                   "sbf\t$cond, $reg1, $reg2, $reg3",
                   []> {
  bits<4> cond;
  let Inst{20-17} = cond;
  let Inst{16} = 0;
}

// MAC reg1, reg2, reg3, reg4 - Multiply-accumulate signed
// (reg3:reg4) = (reg3:reg4) + sext(reg1) * sext(reg2)
// Opcode: 111111, sub-op: 011110, sub-id: 00000
def MAC : FormatXI<0b111111, 0b011110, 0b00000, (outs GPR:$reg3, GPR:$reg4),
                   (ins GPR:$reg1, GPR:$reg2, GPR:$reg3_in, GPR:$reg4_in),
                   "mac\t$reg1, $reg2, $reg3, $reg4",
                   [(set GPR:$reg3, GPR:$reg4,
                         (V850smac GPR:$reg1, GPR:$reg2,
                                   GPR:$reg3_in, GPR:$reg4_in))]>,
          Requires<[HasV850E2M]> {
  let Constraints = "$reg3_in = $reg3, $reg4_in = $reg4";
}

// MACU reg1, reg2, reg3, reg4 - Multiply-accumulate unsigned
// (reg3:reg4) = (reg3:reg4) + zext(reg1) * zext(reg2)
// Opcode: 111111, sub-op: 011111, sub-id: 00000
def MACU : FormatXI<0b111111, 0b011111, 0b00000, (outs GPR:$reg3, GPR:$reg4),
                    (ins GPR:$reg1, GPR:$reg2, GPR:$reg3_in, GPR:$reg4_in),
                    "macu\t$reg1, $reg2, $reg3, $reg4",
                    [(set GPR:$reg3, GPR:$reg4,
                          (V850umac GPR:$reg1, GPR:$reg2,
                                    GPR:$reg3_in, GPR:$reg4_in))]>,
          Requires<[HasV850E2M]> {
  let Constraints = "$reg3_in = $reg3, $reg4_in = $reg4";
}

// SCH0L reg2, reg3 - Search zero from left (count leading ones)
// Opcode: 111111, sub-op: 011010, sub-id: 01100
// Returns position of first 0 bit from MSB (= count of leading 1s)
let Defs = [PSW] in
def SCH0L : FormatXI<0b111111, 0b011010, 0b01100, (outs GPR:$reg3), (ins GPR:$reg2),
                     "sch0l\t$reg2, $reg3",
                     [(set GPR:$reg3, (ctlz (not GPR:$reg2)))]> {
  let reg1 = 0;
}

// SCH0R reg2, reg3 - Search zero from right (count trailing ones)
// Opcode: 111111, sub-op: 011010, sub-id: 01000
// Returns position of first 0 bit from LSB (= count of trailing 1s)
let Defs = [PSW] in
def SCH0R : FormatXI<0b111111, 0b011010, 0b01000, (outs GPR:$reg3), (ins GPR:$reg2),
                     "sch0r\t$reg2, $reg3",
                     [(set GPR:$reg3, (cttz (not GPR:$reg2)))]> {
  let reg1 = 0;
}

// SCH1L reg2, reg3 - Search one from left (count leading zeros)
// Opcode: 111111, sub-op: 011010, sub-id: 01110
// Returns position of first 1 bit from MSB (= count of leading 0s)
// This is __builtin_clz
let Defs = [PSW] in
def SCH1L : FormatXI<0b111111, 0b011010, 0b01110, (outs GPR:$reg3), (ins GPR:$reg2),
                     "sch1l\t$reg2, $reg3",
                     [(set GPR:$reg3, (ctlz GPR:$reg2))]> {
  let reg1 = 0;
}

// SCH1R reg2, reg3 - Search one from right (count trailing zeros)
// Opcode: 111111, sub-op: 011010, sub-id: 01010
// Returns position of first 1 bit from LSB (= count of trailing 0s)
// This is __builtin_ctz
let Defs = [PSW] in
def SCH1R : FormatXI<0b111111, 0b011010, 0b01010, (outs GPR:$reg3), (ins GPR:$reg2),
                     "sch1r\t$reg2, $reg3",
                     [(set GPR:$reg3, (cttz GPR:$reg2))]> {
  let reg1 = 0;
}

//===----------------------------------------------------------------------===//
// 3-operand Shift Instructions (V850E2)
//===----------------------------------------------------------------------===//

// SHR reg1, reg2, reg3 - Shift right logical 3-operand
// Opcode: 111111, sub-op: 000010, sub-id: 00010
// Flags: CY, OV=0, S, Z modified
let Defs = [PSW] in
def SHR_3 : FormatXI<0b111111, 0b000010, 0b00010, (outs GPR:$reg3),
                     (ins GPR:$reg2, GPR:$reg1),
                     "shr\t$reg1, $reg2, $reg3",
                     []>;

// SAR reg1, reg2, reg3 - Shift right arithmetic 3-operand
// Opcode: 111111, sub-op: 000100, sub-id: 00010
// Flags: CY, OV=0, S, Z modified
let Defs = [PSW] in
def SAR_3 : FormatXI<0b111111, 0b000100, 0b00010, (outs GPR:$reg3),
                     (ins GPR:$reg2, GPR:$reg1),
                     "sar\t$reg1, $reg2, $reg3",
                     []>;

// SHL reg1, reg2, reg3 - Shift left logical 3-operand
// Opcode: 111111, sub-op: 000110, sub-id: 00010
// Flags: CY, OV=0, S, Z modified
let Defs = [PSW] in
def SHL_3 : FormatXI<0b111111, 0b000110, 0b00010, (outs GPR:$reg3),
                     (ins GPR:$reg2, GPR:$reg1),
                     "shl\t$reg1, $reg2, $reg3",
                     []>;

//===----------------------------------------------------------------------===//
// 3-operand Saturated Arithmetic Instructions (V850E2)
//===----------------------------------------------------------------------===//

// SATADD reg1, reg2, reg3 - Saturating add 3-operand
// Opcode: 111111, sub-op: 011101, sub-id: 00010
// Flags: CY, OV, S, Z, SAT modified
// Operation: reg3 = saturate(reg2 + reg1)
// Use AddedComplexity to prefer 3-operand over 2-operand when available
let Defs = [PSW], AddedComplexity = 1 in
def SATADD_3 : FormatXI<0b111111, 0b011101, 0b00010, (outs GPR:$reg3),
                        (ins GPR:$reg2, GPR:$reg1),
                        "satadd\t$reg1, $reg2, $reg3",
                        [(set GPR:$reg3, (saddsat GPR:$reg2, GPR:$reg1))]>;

// SATSUB reg1, reg2, reg3 - Saturating subtract 3-operand
// Opcode: 111111, sub-op: 011100, sub-id: 00010
// Flags: CY, OV, S, Z, SAT modified
// Operation: reg3 = saturate(reg2 - reg1)
// Use AddedComplexity to prefer 3-operand over 2-operand when available
let Defs = [PSW], AddedComplexity = 1 in
def SATSUB_3 : FormatXI<0b111111, 0b011100, 0b00010, (outs GPR:$reg3),
                        (ins GPR:$reg2, GPR:$reg1),
                        "satsub\t$reg1, $reg2, $reg3",
                        [(set GPR:$reg3, (ssubsat GPR:$reg2, GPR:$reg1))]>;

//===----------------------------------------------------------------------===//
// HSH Instruction
//===----------------------------------------------------------------------===//

// HSH reg2, reg3 - Halfword swap halfword
// Swaps the two bytes in each halfword independently
// Opcode: 111111, sub-op: 011010, cond: 0011
// Flags: CY, S, Z modified (OV = 0)
let Defs = [PSW] in
def HSH : FormatXII<0b111111, 0b011010, (outs GPR:$reg3), (ins GPR:$reg2),
                    "hsh\t$reg2, $reg3",
                    []> {
  let imm5 = 0;
  let cond = 0b0011;
}

//===----------------------------------------------------------------------===//
// 32-bit Displacement Jump Instructions (V850E2)
// These are 48-bit (6-byte) instructions
// Use same mnemonics as 22-bit forms - assembler picks based on context
//===----------------------------------------------------------------------===//

// JR32 disp32 - Jump relative with 32-bit displacement
// Jumps to PC + disp32
// Uses "jr" mnemonic - same as 22-bit form, selected when displacement requires it
let isBranch = 1, isTerminator = 1, isBarrier = 1 in
def JR32 : FormatVI_E2<0b010111, (outs), (ins brtarget32:$disp32),
                       "jr\t$disp32",
                       []> {
  let reg1 = 0;
}

// JARL32 disp32, reg1 - Jump and register link with 32-bit displacement
// Links return address to reg1 and jumps to PC + disp32
// Uses "jarl" mnemonic - same as 22-bit form
let isCall = 1 in
def JARL32 : FormatVI_E2<0b010111, (outs GPR:$reg1), (ins brtarget32:$disp32),
                         "jarl\t$disp32, $reg1",
                         []>;

// JMP32 disp32[reg1] - Jump with 32-bit displacement
// Jumps to address reg1 + disp32
// Syntax "jmp disp[reg]" is unique - 16-bit JMP uses "jmp [reg]"
let isBranch = 1, isTerminator = 1, isBarrier = 1, isIndirectBranch = 1 in
def JMP32 : FormatVI_E2<0b110111, (outs), (ins GPR:$reg1, brtarget32:$disp32),
                        "jmp\t$disp32[$reg1]",
                        []>;

} // Predicates = [HasV850E2]

//===----------------------------------------------------------------------===//
// V850E2M Instructions (require HasV850E2M predicate)
//===----------------------------------------------------------------------===//

// 4-bit unsigned immediate for FETRAP vector (1-15)
def uimm4_nz : Operand<i32>, ImmLeaf<i32, [{return Imm >= 1 && Imm <= 15;}]> {
  let DecoderMethod = "decodeUImmOperand<4>";
}

// 8-bit unsigned immediate for SYSCALL vector
def uimm8 : Operand<i32>, ImmLeaf<i32, [{return isUInt<8>(Imm);}]> {
  let DecoderMethod = "decodeUImmOperand<8>";
}

let Predicates = [HasV850E2M], DecoderNamespace = "V850E2M" in {

//===----------------------------------------------------------------------===//
// Synchronization Instructions (16-bit)
// These are Format I-like instructions with fixed encodings
//===----------------------------------------------------------------------===//

// SYNCE - Synchronize exceptions
// Waits for all preceding exceptions to be acknowledged before continuing
// Opcode: 0000000000011101
let hasSideEffects = 1 in
def SYNCE : V850Inst16<(outs), (ins),
                       "synce",
                       []> {
  let Inst{15-0} = 0b0000000000011101;
}

// SYNCM - Synchronize memory
// Waits for all preceding memory accesses to complete
// Opcode: 0000000000011110
let hasSideEffects = 1 in
def SYNCM : V850Inst16<(outs), (ins),
                       "syncm",
                       []> {
  let Inst{15-0} = 0b0000000000011110;
}

// SYNCP - Synchronize pipeline
// Waits for all preceding instructions to complete execution
// Opcode: 0000000000011111
let hasSideEffects = 1 in
def SYNCP : V850Inst16<(outs), (ins),
                       "syncp",
                       []> {
  let Inst{15-0} = 0b0000000000011111;
}

//===----------------------------------------------------------------------===//
// RIE - Reserved Instruction Exception (16-bit)
// Triggers a reserved instruction exception
// Opcode: 0000000001000000
//===----------------------------------------------------------------------===//

let hasSideEffects = 1 in
def RIE : V850Inst16<(outs), (ins),
                     "rie",
                     []> {
  let Inst{15-0} = 0b0000000001000000;
}

//===----------------------------------------------------------------------===//
// FETRAP - FE Level Software Trap (16-bit)
// Triggers an FE-level software exception
// Opcode: 0vvvv00001000000 where vvvv is vector4 (1-15, 0 is reserved)
//===----------------------------------------------------------------------===//

let hasSideEffects = 1 in
def FETRAP : V850Inst16<(outs), (ins uimm4_nz:$vector4),
                        "fetrap\t$vector4",
                        []> {
  bits<4> vector4;

  let Inst{15} = 0;
  let Inst{14-11} = vector4;
  let Inst{10-5} = 0b000010;
  let Inst{4-0} = 0b00000;
}

//===----------------------------------------------------------------------===//
// EIRET - Return from EI Level Exception (32-bit)
// Restores PC and PSW from EIPC and EIPSW
// Opcode: 0000011111100000 0000000101001000
//===----------------------------------------------------------------------===//

let isReturn = 1, isTerminator = 1, isBarrier = 1, hasSideEffects = 1,
    Uses = [EIPC, EIPSW], Defs = [PSW] in
def EIRET : V850Inst32<(outs), (ins),
                       "eiret",
                       []> {
  let Inst{15-0} = 0b0000011111100000;
  let Inst{31-16} = 0b0000000101001000;
}

//===----------------------------------------------------------------------===//
// FERET - Return from FE Level Exception (32-bit)
// Restores PC and PSW from FEPC and FEPSW
// Opcode: 0000011111100000 0000000101001010
//===----------------------------------------------------------------------===//

let isReturn = 1, isTerminator = 1, isBarrier = 1, hasSideEffects = 1,
    Uses = [FEPC, FEPSW], Defs = [PSW] in
def FERET : V850Inst32<(outs), (ins),
                       "feret",
                       []> {
  let Inst{15-0} = 0b0000011111100000;
  let Inst{31-16} = 0b0000000101001010;
}

//===----------------------------------------------------------------------===//
// SYSCALL - System Call (32-bit)
// Calls OS system service via table lookup
// Opcode: 11010111111vvvvv 00VVV00101100000
// where vvvvv = vector8[4:0], VVV = vector8[7:5]
//===----------------------------------------------------------------------===//

let isCall = 1, hasSideEffects = 1,
    Defs = [EIPC, EIPSW, PSW] in
def SYSCALL : V850Inst32<(outs), (ins uimm8:$vector8),
                         "syscall\t$vector8",
                         []> {
  bits<8> vector8;

  // First halfword: 11010111111vvvvv
  let Inst{15-11} = 0b11010;
  let Inst{10-5} = 0b111111;
  let Inst{4-0} = vector8{4-0};

  // Second halfword: 00VVV00101100000
  let Inst{31-29} = 0b000;
  let Inst{28-26} = vector8{7-5};
  let Inst{25-16} = 0b0010110000;
}

//===----------------------------------------------------------------------===//
// CAXI - Compare and Exchange for Interlock (32-bit)
// Atomic compare-and-swap operation
// Opcode: rrrrr111111RRRRR wwwww00011101110
// reg2 = rrrrr, reg1 = RRRRR, reg3 = wwwww
//===----------------------------------------------------------------------===//

let mayLoad = 1, mayStore = 1, Defs = [PSW] in
def CAXI : FormatXI<0b111111, 0b000111, 0b01110, (outs GPR:$reg3),
                    (ins GPR:$reg1, GPR:$reg2, GPR:$reg3_in),
                    "caxi\t[$reg1], $reg2, $reg3",
                    []> {
  // reg3 is both input (new value) and output (old value)
  // Semantics: old = *[reg1]; if (old == reg2) *[reg1] = reg3_in; reg3 = old
  let Constraints = "$reg3_in = $reg3";
}

} // Predicates = [HasV850E2M]

let Predicates = [HasV850E2M] in
// Pattern for atomic compare-and-swap (32-bit)
// Maps __sync_val_compare_and_swap, __atomic_compare_exchange, etc.
def : Pat<(atomic_cmp_swap_i32 GPR:$addr, GPR:$expected, GPR:$new),
          (CAXI GPR:$addr, GPR:$expected, GPR:$new)>;

let Predicates = [HasV850FPU] in {

//===----------------------------------------------------------------------===//
// V850E2M FPU Instructions - Single Precision Arithmetic
// Format F:I - 32-bit FPU instructions
// Encoding: reg2[15:11], 111111[10:5], reg1[4:0] | reg3[31:27], subop[26:16]
//===----------------------------------------------------------------------===//

// ADDF.S reg1, reg2, reg3 - Single-precision floating-point add
// reg3 = reg2 + reg1
// Encoding: rrrrr111111RRRRR wwwww1000110000 0
def ADDFS : FormatFPU_RRR<0b0000, (outs FPR:$reg3),
                          (ins FPR:$reg2, FPR:$reg1),
                          "addf.s\t$reg1, $reg2, $reg3",
                          [(set FPR:$reg3, (fadd FPR:$reg2, FPR:$reg1))]>;

// SUBF.S reg1, reg2, reg3 - Single-precision floating-point subtract
// reg3 = reg2 - reg1
// Encoding: rrrrr111111RRRRR wwwww1000110001 0
def SUBFS : FormatFPU_RRR<0b0001, (outs FPR:$reg3),
                          (ins FPR:$reg2, FPR:$reg1),
                          "subf.s\t$reg1, $reg2, $reg3",
                          [(set FPR:$reg3, (fsub FPR:$reg2, FPR:$reg1))]>;

// MULF.S reg1, reg2, reg3 - Single-precision floating-point multiply
// reg3 = reg2 * reg1
// Encoding: rrrrr111111RRRRR wwwww1000110010 0
def MULFS : FormatFPU_RRR<0b0010, (outs FPR:$reg3),
                          (ins FPR:$reg2, FPR:$reg1),
                          "mulf.s\t$reg1, $reg2, $reg3",
                          [(set FPR:$reg3, (fmul FPR:$reg2, FPR:$reg1))]>;

// DIVF.S reg1, reg2, reg3 - Single-precision floating-point divide
// reg3 = reg2 / reg1
// Encoding: rrrrr111111RRRRR wwwww1000110111 0
def DIVFS : FormatFPU_RRR<0b0111, (outs FPR:$reg3),
                          (ins FPR:$reg2, FPR:$reg1),
                          "divf.s\t$reg1, $reg2, $reg3",
                          [(set FPR:$reg3, (fdiv FPR:$reg2, FPR:$reg1))]>;

// MAXF.S reg1, reg2, reg3 - Single-precision floating-point maximum
// reg3 = max(reg2, reg1)
// Encoding: rrrrr111111RRRRR wwwww1000110100 0
def MAXFS : FormatFPU_RRR<0b0100, (outs FPR:$reg3),
                          (ins FPR:$reg2, FPR:$reg1),
                          "maxf.s\t$reg1, $reg2, $reg3",
                          [(set FPR:$reg3, (fmaxnum FPR:$reg2, FPR:$reg1))]>;

// MINF.S reg1, reg2, reg3 - Single-precision floating-point minimum
// reg3 = min(reg2, reg1)
// Encoding: rrrrr111111RRRRR wwwww1000110101 0
def MINFS : FormatFPU_RRR<0b0101, (outs FPR:$reg3),
                          (ins FPR:$reg2, FPR:$reg1),
                          "minf.s\t$reg1, $reg2, $reg3",
                          [(set FPR:$reg3, (fminnum FPR:$reg2, FPR:$reg1))]>;

//===----------------------------------------------------------------------===//
// V850E2M FPU Instructions - Single Precision 2-Operand
// Format F:I with reg1 = 0 (unused)
//===----------------------------------------------------------------------===//

// ABSF.S reg2, reg3 - Single-precision floating-point absolute value
// reg3 = |reg2|
// Encoding: rrrrr111111 00000 wwwww1000100100 0
def ABSFS : FormatFPU_RR<0b0100, (outs FPR:$reg3),
                         (ins FPR:$reg2),
                         "absf.s\t$reg2, $reg3",
                         [(set FPR:$reg3, (fabs FPR:$reg2))]>;

// NEGF.S reg2, reg3 - Single-precision floating-point negate
// reg3 = -reg2
// Encoding: rrrrr111111 00000 wwwww1000101000 0
def NEGFS : FormatFPU_RR<0b1000, (outs FPR:$reg3),
                         (ins FPR:$reg2),
                         "negf.s\t$reg2, $reg3",
                         [(set FPR:$reg3, (fneg FPR:$reg2))]>;

// SQRTF.S reg2, reg3 - Single-precision floating-point square root
// reg3 = sqrt(reg2)
// Encoding: rrrrr111111 00000 wwwww1000101110 0
def SQRTFS : FormatFPU_RR<0b1110, (outs FPR:$reg3),
                          (ins FPR:$reg2),
                          "sqrtf.s\t$reg2, $reg3",
                          [(set FPR:$reg3, (fsqrt FPR:$reg2))]>;

// RECIPF.S reg2, reg3 - Single-precision floating-point reciprocal
// reg3 = 1 / reg2
// Encoding: rrrrr111111 00001 wwwww1000101110 0
let Defs = [FPSR] in
def RECIPFS : V850Inst32<(outs GPR:$reg3), (ins GPR:$reg2),
                         "recipf.s\t$reg2, $reg3",
                         []> {
  bits<5> reg2;
  bits<5> reg3;

  let Inst{15-11} = reg2;
  let Inst{10-5}  = 0b111111;
  let Inst{4-0}   = 0b00001;
  let Inst{31-27} = reg3;
  let Inst{26}    = 1;
  let Inst{25-23} = 0b000;
  let Inst{22-21} = 0b10;
  let Inst{20-17} = 0b1110;
  let Inst{16}    = 0;
}

// RSQRTF.S reg2, reg3 - Single-precision reciprocal square root
// reg3 = 1 / sqrt(reg2)
// Encoding: rrrrr111111 00010 wwwww1000101110 0
let Defs = [FPSR] in
def RSQRTFS : V850Inst32<(outs GPR:$reg3), (ins GPR:$reg2),
                          "rsqrtf.s\t$reg2, $reg3",
                          []> {
  bits<5> reg2;
  bits<5> reg3;

  let Inst{15-11} = reg2;
  let Inst{10-5}  = 0b111111;
  let Inst{4-0}   = 0b00010;
  let Inst{31-27} = reg3;
  let Inst{26}    = 1;
  let Inst{25-23} = 0b000;
  let Inst{22-21} = 0b10;
  let Inst{20-17} = 0b1110;
  let Inst{16}    = 0;
}

//===----------------------------------------------------------------------===//
// V850E2M FPU Instructions - Double Precision Arithmetic
// Double precision uses even register pairs (r0, r2, r4, ..., r30)
// For a 64-bit value, it uses {rN+1, rN} where N is even
// The low bit of each register field (bits 0, 11, 27) must be 0 for double
//===----------------------------------------------------------------------===//

// ADDF.D reg1, reg2, reg3 - Double-precision floating-point add
// reg3 = reg2 + reg1 (uses register pairs)
// Encoding: rrrr0111111RRRR0 wwww01000111000 0
def ADDFD : V850Inst32<(outs GPR:$reg3), (ins GPR:$reg2, GPR:$reg1),
                       "addf.d\t$reg1, $reg2, $reg3", []> {
  bits<5> reg1;
  bits<5> reg2;
  bits<5> reg3;

  let Inst{15-12} = reg2{4-1};
  let Inst{11}    = 0;              // Even register constraint
  let Inst{10-5}  = 0b111111;
  let Inst{4-1}   = reg1{4-1};
  let Inst{0}     = 0;              // Even register constraint
  let Inst{31-28} = reg3{4-1};
  let Inst{27}    = 0;              // Even register constraint
  let Inst{26}    = 1;
  let Inst{25-23} = 0b000;
  let Inst{22-21} = 0b11;
  let Inst{20-17} = 0b1000;
  let Inst{16}    = 0;
}

// SUBF.D reg1, reg2, reg3 - Double-precision floating-point subtract
// reg3 = reg2 - reg1
def SUBFD : V850Inst32<(outs GPR:$reg3), (ins GPR:$reg2, GPR:$reg1),
                       "subf.d\t$reg1, $reg2, $reg3", []> {
  bits<5> reg1;
  bits<5> reg2;
  bits<5> reg3;

  let Inst{15-12} = reg2{4-1};
  let Inst{11}    = 0;
  let Inst{10-5}  = 0b111111;
  let Inst{4-1}   = reg1{4-1};
  let Inst{0}     = 0;
  let Inst{31-28} = reg3{4-1};
  let Inst{27}    = 0;
  let Inst{26}    = 1;
  let Inst{25-23} = 0b000;
  let Inst{22-21} = 0b11;
  let Inst{20-17} = 0b1001;
  let Inst{16}    = 0;
}

// MULF.D reg1, reg2, reg3 - Double-precision floating-point multiply
// reg3 = reg2 * reg1
def MULFD : V850Inst32<(outs GPR:$reg3), (ins GPR:$reg2, GPR:$reg1),
                       "mulf.d\t$reg1, $reg2, $reg3", []> {
  bits<5> reg1;
  bits<5> reg2;
  bits<5> reg3;

  let Inst{15-12} = reg2{4-1};
  let Inst{11}    = 0;
  let Inst{10-5}  = 0b111111;
  let Inst{4-1}   = reg1{4-1};
  let Inst{0}     = 0;
  let Inst{31-28} = reg3{4-1};
  let Inst{27}    = 0;
  let Inst{26}    = 1;
  let Inst{25-23} = 0b000;
  let Inst{22-21} = 0b11;
  let Inst{20-17} = 0b1010;
  let Inst{16}    = 0;
}

// DIVF.D reg1, reg2, reg3 - Double-precision floating-point divide
// reg3 = reg2 / reg1
def DIVFD : V850Inst32<(outs GPR:$reg3), (ins GPR:$reg2, GPR:$reg1),
                       "divf.d\t$reg1, $reg2, $reg3", []> {
  bits<5> reg1;
  bits<5> reg2;
  bits<5> reg3;

  let Inst{15-12} = reg2{4-1};
  let Inst{11}    = 0;
  let Inst{10-5}  = 0b111111;
  let Inst{4-1}   = reg1{4-1};
  let Inst{0}     = 0;
  let Inst{31-28} = reg3{4-1};
  let Inst{27}    = 0;
  let Inst{26}    = 1;
  let Inst{25-23} = 0b000;
  let Inst{22-21} = 0b11;
  let Inst{20-17} = 0b1111;
  let Inst{16}    = 0;
}

// MAXF.D reg1, reg2, reg3 - Double-precision floating-point maximum
// reg3 = max(reg2, reg1)
def MAXFD : V850Inst32<(outs GPR:$reg3), (ins GPR:$reg2, GPR:$reg1),
                       "maxf.d\t$reg1, $reg2, $reg3", []> {
  bits<5> reg1;
  bits<5> reg2;
  bits<5> reg3;

  let Inst{15-12} = reg2{4-1};
  let Inst{11}    = 0;
  let Inst{10-5}  = 0b111111;
  let Inst{4-1}   = reg1{4-1};
  let Inst{0}     = 0;
  let Inst{31-28} = reg3{4-1};
  let Inst{27}    = 0;
  let Inst{26}    = 1;
  let Inst{25-23} = 0b000;
  let Inst{22-21} = 0b11;
  let Inst{20-17} = 0b1100;
  let Inst{16}    = 0;
}

// MINF.D reg1, reg2, reg3 - Double-precision floating-point minimum
// reg3 = min(reg2, reg1)
def MINFD : V850Inst32<(outs GPR:$reg3), (ins GPR:$reg2, GPR:$reg1),
                       "minf.d\t$reg1, $reg2, $reg3", []> {
  bits<5> reg1;
  bits<5> reg2;
  bits<5> reg3;

  let Inst{15-12} = reg2{4-1};
  let Inst{11}    = 0;
  let Inst{10-5}  = 0b111111;
  let Inst{4-1}   = reg1{4-1};
  let Inst{0}     = 0;
  let Inst{31-28} = reg3{4-1};
  let Inst{27}    = 0;
  let Inst{26}    = 1;
  let Inst{25-23} = 0b000;
  let Inst{22-21} = 0b11;
  let Inst{20-17} = 0b1101;
  let Inst{16}    = 0;
}

//===----------------------------------------------------------------------===//
// V850E2M FPU Instructions - Double Precision 2-Operand
//===----------------------------------------------------------------------===//

// ABSF.D reg2, reg3 - Double-precision floating-point absolute value
// reg3 = |reg2|
def ABSFD : V850Inst32<(outs GPR:$reg3), (ins GPR:$reg2),
                       "absf.d\t$reg2, $reg3", []> {
  bits<5> reg2;
  bits<5> reg3;

  let Inst{15-12} = reg2{4-1};
  let Inst{11}    = 0;
  let Inst{10-5}  = 0b111111;
  let Inst{4-0}   = 0;
  let Inst{31-28} = reg3{4-1};
  let Inst{27}    = 0;
  let Inst{26}    = 1;
  let Inst{25-23} = 0b000;
  let Inst{22-21} = 0b10;
  let Inst{20-17} = 0b1100;
  let Inst{16}    = 0;
}

// NEGF.D reg2, reg3 - Double-precision floating-point negate
// reg3 = -reg2
def NEGFD : V850Inst32<(outs GPR:$reg3), (ins GPR:$reg2),
                       "negf.d\t$reg2, $reg3", []> {
  bits<5> reg2;
  bits<5> reg3;

  let Inst{15-12} = reg2{4-1};
  let Inst{11}    = 0;
  let Inst{10-5}  = 0b111111;
  let Inst{4-0}   = 0b00001;
  let Inst{31-28} = reg3{4-1};
  let Inst{27}    = 0;
  let Inst{26}    = 1;
  let Inst{25-23} = 0b000;
  let Inst{22-21} = 0b10;
  let Inst{20-17} = 0b1000;
  let Inst{16}    = 0;
}

// SQRTF.D reg2, reg3 - Double-precision floating-point square root
// reg3 = sqrt(reg2)
def SQRTFD : V850Inst32<(outs GPR:$reg3), (ins GPR:$reg2),
                        "sqrtf.d\t$reg2, $reg3", []> {
  bits<5> reg2;
  bits<5> reg3;

  let Inst{15-12} = reg2{4-1};
  let Inst{11}    = 0;
  let Inst{10-5}  = 0b111111;
  let Inst{4-0}   = 0;
  let Inst{31-28} = reg3{4-1};
  let Inst{27}    = 0;
  let Inst{26}    = 1;
  let Inst{25-23} = 0b000;
  let Inst{22-21} = 0b10;
  let Inst{20-17} = 0b1110;
  let Inst{16}    = 0;
}

// RECIPF.D reg2, reg3 - Double-precision floating-point reciprocal
// reg3 = 1 / reg2
let Defs = [FPSR] in
def RECIPFD : V850Inst32<(outs GPR:$reg3), (ins GPR:$reg2),
                         "recipf.d\t$reg2, $reg3", []> {
  bits<5> reg2;
  bits<5> reg3;

  let Inst{15-12} = reg2{4-1};
  let Inst{11}    = 0;
  let Inst{10-5}  = 0b111111;
  let Inst{4-0}   = 0b00001;
  let Inst{31-28} = reg3{4-1};
  let Inst{27}    = 0;
  let Inst{26}    = 1;
  let Inst{25-23} = 0b000;
  let Inst{22-21} = 0b10;
  let Inst{20-17} = 0b1110;
  let Inst{16}    = 0;
}

// RSQRTF.D reg2, reg3 - Double-precision reciprocal square root
// reg3 = 1 / sqrt(reg2)
let Defs = [FPSR] in
def RSQRTFD : V850Inst32<(outs GPR:$reg3), (ins GPR:$reg2),
                          "rsqrtf.d\t$reg2, $reg3", []> {
  bits<5> reg2;
  bits<5> reg3;

  let Inst{15-12} = reg2{4-1};
  let Inst{11}    = 0;
  let Inst{10-5}  = 0b111111;
  let Inst{4-0}   = 0b00010;
  let Inst{31-28} = reg3{4-1};
  let Inst{27}    = 0;
  let Inst{26}    = 1;
  let Inst{25-23} = 0b000;
  let Inst{22-21} = 0b10;
  let Inst{20-17} = 0b1110;
  let Inst{16}    = 0;
}

//===----------------------------------------------------------------------===//
// V850E2M FPU Instructions - Multiply-Add (Single Precision Only)
// Format: reg4 = (reg2 * reg1) +/- reg3
//===----------------------------------------------------------------------===//

// MADDF.S reg1, reg2, reg3, reg4 - Floating-point multiply-add
// reg4 = (reg2 * reg1) + reg3
def MADDFS : FormatFPU_RRRR<0b00, (outs GPR:$reg4),
                            (ins GPR:$reg2, GPR:$reg1, GPR:$reg3),
                            "maddf.s\t$reg1, $reg2, $reg3, $reg4",
                            []>;

// MSUBF.S reg1, reg2, reg3, reg4 - Floating-point multiply-subtract
// reg4 = (reg2 * reg1) - reg3
def MSUBFS : FormatFPU_RRRR<0b01, (outs GPR:$reg4),
                            (ins GPR:$reg2, GPR:$reg1, GPR:$reg3),
                            "msubf.s\t$reg1, $reg2, $reg3, $reg4",
                            []>;

// NMADDF.S reg1, reg2, reg3, reg4 - Floating-point negate multiply-add
// reg4 = -((reg2 * reg1) + reg3)
def NMADDFS : FormatFPU_RRRR<0b10, (outs GPR:$reg4),
                             (ins GPR:$reg2, GPR:$reg1, GPR:$reg3),
                             "nmaddf.s\t$reg1, $reg2, $reg3, $reg4",
                             []>;

// NMSUBF.S reg1, reg2, reg3, reg4 - Floating-point negate multiply-subtract
// reg4 = -((reg2 * reg1) - reg3)
def NMSUBFS : FormatFPU_RRRR<0b11, (outs GPR:$reg4),
                             (ins GPR:$reg2, GPR:$reg1, GPR:$reg3),
                             "nmsubf.s\t$reg1, $reg2, $reg3, $reg4",
                             []>;

//===----------------------------------------------------------------------===//
// V850E2M FPU Instructions - Transfer FPSR to PSW
//===----------------------------------------------------------------------===//

// TRFSR fcbit - Transfer floating-point condition to PSW.Z
// PSW.Z = FPCC[fcbit]
let Defs = [PSW], Uses = [FPCC] in
def TRFSR : FormatFPU_TRFSR<(outs), (ins uimm3:$fcbit),
                            "trfsr\t$fcbit",
                            []>;

//===----------------------------------------------------------------------===//
// V850E2M FPU Instructions - Comparison
// CMPF.S/CMPF.D - Compare floating-point values
// Sets FPCC[fcbit] based on comparison result using condition fcond
//
// fcond values:
//   0 (F)    - False
//   1 (UN)   - Unordered
//   2 (EQ)   - Equal
//   3 (UEQ)  - Unordered or Equal
//   4 (OLT)  - Ordered Less Than
//   5 (ULT)  - Unordered or Less Than
//   6 (OLE)  - Ordered Less or Equal
//   7 (ULE)  - Unordered or Less or Equal
//   8 (SF)   - Signaling False
//   9 (NGLE) - Not Greater, Less, or Equal
//  10 (SEQ)  - Signaling Equal
//  11 (NGL)  - Not Greater or Less
//  12 (LT)   - Less Than
//  13 (NGE)  - Not Greater or Equal
//  14 (LE)   - Less or Equal
//  15 (NGT)  - Not Greater Than
//===----------------------------------------------------------------------===//

// CMPF.S fcond, reg1, reg2, fcbit - Single-precision compare
// FPCC[fcbit] = reg2 cmp reg1 (using fcond)
let Defs = [FPCC] in
def CMPFS : FormatFPU_CMP<0, (outs), (ins uimm4:$fcond, GPR:$reg1, GPR:$reg2, uimm3:$fcbit),
                          "cmpf.s\t$fcond, $reg1, $reg2, $fcbit",
                          []>;

// CMPF.D fcond, reg1, reg2, fcbit - Double-precision compare
// FPCC[fcbit] = reg2 cmp reg1 (using fcond)
// Note: reg1 and reg2 must be even registers (specify lower register of pair)
let Defs = [FPCC] in
def CMPFD : FormatFPU_CMP<1, (outs), (ins uimm4:$fcond, GPR:$reg1, GPR:$reg2, uimm3:$fcbit),
                          "cmpf.d\t$fcond, $reg1, $reg2, $fcbit",
                          []>;

//===----------------------------------------------------------------------===//
// V850E2M FPU Instructions - Conversion
//
// Conversion between floating-point formats and integer formats.
// Register requirements:
// - Single-precision (S): any GPR
// - Double-precision (D): even GPR (specifies lower register of pair)
// - Word (W): any GPR (32-bit integer)
// - Long (L): even GPR (specifies lower register of 64-bit pair)
//===----------------------------------------------------------------------===//

//--- Floating-point to floating-point conversions ---

// CVTF.DS reg2, reg3 - Double to Single (subop2=3, cat=0, type=2, subop=9)
def CVTFDS : FormatFPU_CVT<0b00011, 0b000, 0b10, 0b1001,
                           (outs GPR:$reg3), (ins GPR:$reg2),
                           "cvtf.ds\t$reg2, $reg3", []>;

// CVTF.SD reg2, reg3 - Single to Double (subop2=2, cat=0, type=2, subop=9)
def CVTFSD : FormatFPU_CVT<0b00010, 0b000, 0b10, 0b1001,
                           (outs GPR:$reg3), (ins GPR:$reg2),
                           "cvtf.sd\t$reg2, $reg3", []>;

//--- Signed integer to floating-point conversions ---

// CVTF.WS reg2, reg3 - Word (int32) to Single (subop2=0, cat=0, type=2, subop=1)
def CVTFWS : FormatFPU_CVT<0b00000, 0b000, 0b10, 0b0001,
                           (outs FPR:$reg3), (ins GPR:$reg2),
                           "cvtf.ws\t$reg2, $reg3",
                           [(set FPR:$reg3, (sint_to_fp GPR:$reg2))]>;

// CVTF.WD reg2, reg3 - Word (int32) to Double (subop2=0, cat=0, type=2, subop=9)
def CVTFWD : FormatFPU_CVT<0b00000, 0b000, 0b10, 0b1001,
                           (outs GPR:$reg3), (ins GPR:$reg2),
                           "cvtf.wd\t$reg2, $reg3", []>;

// CVTF.LS reg2, reg3 - Long (int64) to Single (subop2=1, cat=0, type=2, subop=1)
def CVTFLS : FormatFPU_CVT<0b00001, 0b000, 0b10, 0b0001,
                           (outs GPR:$reg3), (ins GPR:$reg2),
                           "cvtf.ls\t$reg2, $reg3", []>;

// CVTF.LD reg2, reg3 - Long (int64) to Double (subop2=1, cat=0, type=2, subop=9)
def CVTFLD : FormatFPU_CVT<0b00001, 0b000, 0b10, 0b1001,
                           (outs GPR:$reg3), (ins GPR:$reg2),
                           "cvtf.ld\t$reg2, $reg3", []>;

//--- Floating-point to signed integer conversions ---

// CVTF.SW reg2, reg3 - Single to Word (subop2=4, cat=0, type=2, subop=0)
def CVTFSW : FormatFPU_CVT<0b00100, 0b000, 0b10, 0b0000,
                           (outs GPR:$reg3), (ins GPR:$reg2),
                           "cvtf.sw\t$reg2, $reg3", []>;

// CVTF.DW reg2, reg3 - Double to Word (subop2=4, cat=0, type=2, subop=8)
def CVTFDW : FormatFPU_CVT<0b00100, 0b000, 0b10, 0b1000,
                           (outs GPR:$reg3), (ins GPR:$reg2),
                           "cvtf.dw\t$reg2, $reg3", []>;

// CVTF.SL reg2, reg3 - Single to Long (subop2=4, cat=0, type=2, subop=2)
def CVTFSL : FormatFPU_CVT<0b00100, 0b000, 0b10, 0b0010,
                           (outs GPR:$reg3), (ins GPR:$reg2),
                           "cvtf.sl\t$reg2, $reg3", []>;

// CVTF.DL reg2, reg3 - Double to Long (subop2=4, cat=0, type=2, subop=10)
def CVTFDL : FormatFPU_CVT<0b00100, 0b000, 0b10, 0b1010,
                           (outs GPR:$reg3), (ins GPR:$reg2),
                           "cvtf.dl\t$reg2, $reg3", []>;

//--- Unsigned integer to floating-point conversions ---

// CVTF.UWS reg2, reg3 - Unsigned Word to Single (subop2=16, cat=0, type=2, subop=1)
def CVTFUWS : FormatFPU_CVT<0b10000, 0b000, 0b10, 0b0001,
                            (outs GPR:$reg3), (ins GPR:$reg2),
                            "cvtf.uws\t$reg2, $reg3", []>;

// CVTF.UWD reg2, reg3 - Unsigned Word to Double (subop2=16, cat=0, type=2, subop=9)
def CVTFUWD : FormatFPU_CVT<0b10000, 0b000, 0b10, 0b1001,
                            (outs GPR:$reg3), (ins GPR:$reg2),
                            "cvtf.uwd\t$reg2, $reg3", []>;

// CVTF.ULS reg2, reg3 - Unsigned Long to Single (subop2=17, cat=0, type=2, subop=1)
def CVTFULS : FormatFPU_CVT<0b10001, 0b000, 0b10, 0b0001,
                            (outs GPR:$reg3), (ins GPR:$reg2),
                            "cvtf.uls\t$reg2, $reg3", []>;

// CVTF.ULD reg2, reg3 - Unsigned Long to Double (subop2=17, cat=0, type=2, subop=9)
def CVTFULD : FormatFPU_CVT<0b10001, 0b000, 0b10, 0b1001,
                            (outs GPR:$reg3), (ins GPR:$reg2),
                            "cvtf.uld\t$reg2, $reg3", []>;

//--- Floating-point to unsigned integer conversions ---

// CVTF.SUW reg2, reg3 - Single to Unsigned Word (subop2=20, cat=0, type=2, subop=0)
def CVTFSUW : FormatFPU_CVT<0b10100, 0b000, 0b10, 0b0000,
                            (outs GPR:$reg3), (ins GPR:$reg2),
                            "cvtf.suw\t$reg2, $reg3", []>;

// CVTF.DUW reg2, reg3 - Double to Unsigned Word (subop2=20, cat=0, type=2, subop=8)
def CVTFDUW : FormatFPU_CVT<0b10100, 0b000, 0b10, 0b1000,
                            (outs GPR:$reg3), (ins GPR:$reg2),
                            "cvtf.duw\t$reg2, $reg3", []>;

// CVTF.SUL reg2, reg3 - Single to Unsigned Long (subop2=20, cat=0, type=2, subop=2)
def CVTFSUL : FormatFPU_CVT<0b10100, 0b000, 0b10, 0b0010,
                            (outs GPR:$reg3), (ins GPR:$reg2),
                            "cvtf.sul\t$reg2, $reg3", []>;

// CVTF.DUL reg2, reg3 - Double to Unsigned Long (subop2=20, cat=0, type=2, subop=10)
def CVTFDUL : FormatFPU_CVT<0b10100, 0b000, 0b10, 0b1010,
                            (outs GPR:$reg3), (ins GPR:$reg2),
                            "cvtf.dul\t$reg2, $reg3", []>;

//===----------------------------------------------------------------------===//
// FPU Rounding Instructions - V850E2M
// TRNCF - Truncate (round toward zero)
// CEILF - Ceiling (round toward +infinity)
// FLOORF - Floor (round toward -infinity)
//===----------------------------------------------------------------------===//

// --- TRNCF (Truncate) - Signed ---
// TRNCF.SW reg2, reg3 - Truncate Single to Word (subop2=1, cat=0, type=2, subop=0)
def TRNCFSW : FormatFPU_CVT<0b00001, 0b000, 0b10, 0b0000,
                            (outs GPR:$reg3), (ins FPR:$reg2),
                            "trncf.sw\t$reg2, $reg3",
                            [(set GPR:$reg3, (fp_to_sint FPR:$reg2))]>;

// TRNCF.DW reg2, reg3 - Truncate Double to Word (subop2=1, cat=0, type=2, subop=8)
def TRNCFDW : FormatFPU_CVT<0b00001, 0b000, 0b10, 0b1000,
                            (outs GPR:$reg3), (ins GPR:$reg2),
                            "trncf.dw\t$reg2, $reg3", []>;

// TRNCF.SL reg2, reg3 - Truncate Single to Long (subop2=1, cat=0, type=2, subop=2)
def TRNCFSL : FormatFPU_CVT<0b00001, 0b000, 0b10, 0b0010,
                            (outs GPR:$reg3), (ins GPR:$reg2),
                            "trncf.sl\t$reg2, $reg3", []>;

// TRNCF.DL reg2, reg3 - Truncate Double to Long (subop2=1, cat=0, type=2, subop=10)
def TRNCFDL : FormatFPU_CVT<0b00001, 0b000, 0b10, 0b1010,
                            (outs GPR:$reg3), (ins GPR:$reg2),
                            "trncf.dl\t$reg2, $reg3", []>;

// --- TRNCF (Truncate) - Unsigned ---
// TRNCF.SUW reg2, reg3 - Truncate Single to Unsigned Word (subop2=17, cat=0, type=2, subop=0)
def TRNCFSUW : FormatFPU_CVT<0b10001, 0b000, 0b10, 0b0000,
                             (outs GPR:$reg3), (ins GPR:$reg2),
                             "trncf.suw\t$reg2, $reg3", []>;

// TRNCF.DUW reg2, reg3 - Truncate Double to Unsigned Word (subop2=17, cat=0, type=2, subop=8)
def TRNCFDUW : FormatFPU_CVT<0b10001, 0b000, 0b10, 0b1000,
                             (outs GPR:$reg3), (ins GPR:$reg2),
                             "trncf.duw\t$reg2, $reg3", []>;

// TRNCF.SUL reg2, reg3 - Truncate Single to Unsigned Long (subop2=17, cat=0, type=2, subop=2)
def TRNCFSUL : FormatFPU_CVT<0b10001, 0b000, 0b10, 0b0010,
                             (outs GPR:$reg3), (ins GPR:$reg2),
                             "trncf.sul\t$reg2, $reg3", []>;

// TRNCF.DUL reg2, reg3 - Truncate Double to Unsigned Long (subop2=17, cat=0, type=2, subop=10)
def TRNCFDUL : FormatFPU_CVT<0b10001, 0b000, 0b10, 0b1010,
                             (outs GPR:$reg3), (ins GPR:$reg2),
                             "trncf.dul\t$reg2, $reg3", []>;

// --- CEILF (Ceiling) - Signed ---
// CEILF.SW reg2, reg3 - Ceiling Single to Word (subop2=2, cat=0, type=2, subop=0)
def CEILFSW : FormatFPU_CVT<0b00010, 0b000, 0b10, 0b0000,
                            (outs GPR:$reg3), (ins GPR:$reg2),
                            "ceilf.sw\t$reg2, $reg3", []>;

// CEILF.DW reg2, reg3 - Ceiling Double to Word (subop2=2, cat=0, type=2, subop=8)
def CEILFDW : FormatFPU_CVT<0b00010, 0b000, 0b10, 0b1000,
                            (outs GPR:$reg3), (ins GPR:$reg2),
                            "ceilf.dw\t$reg2, $reg3", []>;

// CEILF.SL reg2, reg3 - Ceiling Single to Long (subop2=2, cat=0, type=2, subop=2)
def CEILFSL : FormatFPU_CVT<0b00010, 0b000, 0b10, 0b0010,
                            (outs GPR:$reg3), (ins GPR:$reg2),
                            "ceilf.sl\t$reg2, $reg3", []>;

// CEILF.DL reg2, reg3 - Ceiling Double to Long (subop2=2, cat=0, type=2, subop=10)
def CEILFDL : FormatFPU_CVT<0b00010, 0b000, 0b10, 0b1010,
                            (outs GPR:$reg3), (ins GPR:$reg2),
                            "ceilf.dl\t$reg2, $reg3", []>;

// --- CEILF (Ceiling) - Unsigned ---
// CEILF.SUW reg2, reg3 - Ceiling Single to Unsigned Word (subop2=18, cat=0, type=2, subop=0)
def CEILFSUW : FormatFPU_CVT<0b10010, 0b000, 0b10, 0b0000,
                             (outs GPR:$reg3), (ins GPR:$reg2),
                             "ceilf.suw\t$reg2, $reg3", []>;

// CEILF.DUW reg2, reg3 - Ceiling Double to Unsigned Word (subop2=18, cat=0, type=2, subop=8)
def CEILFDUW : FormatFPU_CVT<0b10010, 0b000, 0b10, 0b1000,
                             (outs GPR:$reg3), (ins GPR:$reg2),
                             "ceilf.duw\t$reg2, $reg3", []>;

// CEILF.SUL reg2, reg3 - Ceiling Single to Unsigned Long (subop2=18, cat=0, type=2, subop=2)
def CEILFSUL : FormatFPU_CVT<0b10010, 0b000, 0b10, 0b0010,
                             (outs GPR:$reg3), (ins GPR:$reg2),
                             "ceilf.sul\t$reg2, $reg3", []>;

// CEILF.DUL reg2, reg3 - Ceiling Double to Unsigned Long (subop2=18, cat=0, type=2, subop=10)
def CELIFDUL : FormatFPU_CVT<0b10010, 0b000, 0b10, 0b1010,
                             (outs GPR:$reg3), (ins GPR:$reg2),
                             "ceilf.dul\t$reg2, $reg3", []>;

// --- FLOORF (Floor) - Signed ---
// FLOORF.SW reg2, reg3 - Floor Single to Word (subop2=3, cat=0, type=2, subop=0)
def FLOORFSW : FormatFPU_CVT<0b00011, 0b000, 0b10, 0b0000,
                             (outs GPR:$reg3), (ins GPR:$reg2),
                             "floorf.sw\t$reg2, $reg3", []>;

// FLOORF.DW reg2, reg3 - Floor Double to Word (subop2=3, cat=0, type=2, subop=8)
def FLOORFDW : FormatFPU_CVT<0b00011, 0b000, 0b10, 0b1000,
                             (outs GPR:$reg3), (ins GPR:$reg2),
                             "floorf.dw\t$reg2, $reg3", []>;

// FLOORF.SL reg2, reg3 - Floor Single to Long (subop2=3, cat=0, type=2, subop=2)
def FLOORFSL : FormatFPU_CVT<0b00011, 0b000, 0b10, 0b0010,
                             (outs GPR:$reg3), (ins GPR:$reg2),
                             "floorf.sl\t$reg2, $reg3", []>;

// FLOORF.DL reg2, reg3 - Floor Double to Long (subop2=3, cat=0, type=2, subop=10)
def FLOORFDL : FormatFPU_CVT<0b00011, 0b000, 0b10, 0b1010,
                             (outs GPR:$reg3), (ins GPR:$reg2),
                             "floorf.dl\t$reg2, $reg3", []>;

// --- FLOORF (Floor) - Unsigned ---
// FLOORF.SUW reg2, reg3 - Floor Single to Unsigned Word (subop2=19, cat=0, type=2, subop=0)
def FLOORFSUW : FormatFPU_CVT<0b10011, 0b000, 0b10, 0b0000,
                              (outs GPR:$reg3), (ins GPR:$reg2),
                              "floorf.suw\t$reg2, $reg3", []>;

// FLOORF.DUW reg2, reg3 - Floor Double to Unsigned Word (subop2=19, cat=0, type=2, subop=8)
def FLOORFDUW : FormatFPU_CVT<0b10011, 0b000, 0b10, 0b1000,
                              (outs GPR:$reg3), (ins GPR:$reg2),
                              "floorf.duw\t$reg2, $reg3", []>;

// FLOORF.SUL reg2, reg3 - Floor Single to Unsigned Long (subop2=19, cat=0, type=2, subop=2)
def FLOORFSUL : FormatFPU_CVT<0b10011, 0b000, 0b10, 0b0010,
                              (outs GPR:$reg3), (ins GPR:$reg2),
                              "floorf.sul\t$reg2, $reg3", []>;

// FLOORF.DUL reg2, reg3 - Floor Double to Unsigned Long (subop2=19, cat=0, type=2, subop=10)
def FLOORFDUL : FormatFPU_CVT<0b10011, 0b000, 0b10, 0b1010,
                              (outs GPR:$reg3), (ins GPR:$reg2),
                              "floorf.dul\t$reg2, $reg3", []>;

//===----------------------------------------------------------------------===//
// FPU System Register Access via BSEL Banking (V850E2M+)
//
// These pseudo-instructions handle the BSEL register switching required
// to access FPU system registers on V850E2M. The FPU registers (regID 6-11)
// are only accessible when BSEL=0x2000 (FPU Status Bank).
//
// Expansion sequence for reading:
//   movhi 0x20, r0, $scratch  ; $scratch = 0x2000
//   ldsr  $scratch, bsel      ; Select FPU bank
//   stsr  fpu_reg, $result    ; Read FPU register
//   mov   r0, $scratch
//   ldsr  $scratch, bsel      ; Restore CPU main bank
//
// Expansion sequence for writing:
//   movhi 0x20, r0, $scratch  ; $scratch = 0x2000
//   ldsr  $scratch, bsel      ; Select FPU bank
//   ldsr  $value, fpu_reg     ; Write FPU register
//   mov   r0, $scratch
//   ldsr  $scratch, bsel      ; Restore CPU main bank
//===----------------------------------------------------------------------===//

// Read FPSR with automatic BSEL handling
let usesCustomInserter = 1, Predicates = [HasV850E2M, HasV850FPU],
    Defs = [BSEL], hasSideEffects = 1 in {
def READ_FPSR : V850Pseudo<(outs GPR:$result), (ins),
                           "# READ_FPSR -> $result",
                           [(set GPR:$result, (int_v850_read_fpsr))]>;

def READ_FPEPC : V850Pseudo<(outs GPR:$result), (ins),
                            "# READ_FPEPC -> $result",
                            [(set GPR:$result, (int_v850_read_fpepc))]>;

def READ_FPST : V850Pseudo<(outs GPR:$result), (ins),
                           "# READ_FPST -> $result",
                           [(set GPR:$result, (int_v850_read_fpst))]>;

def READ_FPCC : V850Pseudo<(outs GPR:$result), (ins),
                           "# READ_FPCC -> $result",
                           [(set GPR:$result, (int_v850_read_fpcc))]>;

def READ_FPCFG : V850Pseudo<(outs GPR:$result), (ins),
                            "# READ_FPCFG -> $result",
                            [(set GPR:$result, (int_v850_read_fpcfg))]>;

def READ_FPEC : V850Pseudo<(outs GPR:$result), (ins),
                           "# READ_FPEC -> $result",
                           [(set GPR:$result, (int_v850_read_fpec))]>;
}

// Write FPU registers with automatic BSEL handling
let usesCustomInserter = 1, Predicates = [HasV850E2M, HasV850FPU],
    Defs = [BSEL, FPSR], hasSideEffects = 1 in
def WRITE_FPSR : V850Pseudo<(outs), (ins GPR:$value),
                            "# WRITE_FPSR $value",
                            [(int_v850_write_fpsr GPR:$value)]>;

let usesCustomInserter = 1, Predicates = [HasV850E2M, HasV850FPU],
    Defs = [BSEL, FPEPC], hasSideEffects = 1 in
def WRITE_FPEPC : V850Pseudo<(outs), (ins GPR:$value),
                             "# WRITE_FPEPC $value",
                             [(int_v850_write_fpepc GPR:$value)]>;

let usesCustomInserter = 1, Predicates = [HasV850E2M, HasV850FPU],
    Defs = [BSEL, FPST], hasSideEffects = 1 in
def WRITE_FPST : V850Pseudo<(outs), (ins GPR:$value),
                            "# WRITE_FPST $value",
                            [(int_v850_write_fpst GPR:$value)]>;

let usesCustomInserter = 1, Predicates = [HasV850E2M, HasV850FPU],
    Defs = [BSEL, FPCC], hasSideEffects = 1 in
def WRITE_FPCC : V850Pseudo<(outs), (ins GPR:$value),
                            "# WRITE_FPCC $value",
                            [(int_v850_write_fpcc GPR:$value)]>;

let usesCustomInserter = 1, Predicates = [HasV850E2M, HasV850FPU],
    Defs = [BSEL, FPCFG], hasSideEffects = 1 in
def WRITE_FPCFG : V850Pseudo<(outs), (ins GPR:$value),
                             "# WRITE_FPCFG $value",
                             [(int_v850_write_fpcfg GPR:$value)]>;

let usesCustomInserter = 1, Predicates = [HasV850E2M, HasV850FPU],
    Defs = [BSEL, FPEC], hasSideEffects = 1 in
def WRITE_FPEC : V850Pseudo<(outs), (ins GPR:$value),
                            "# WRITE_FPEC $value",
                            [(int_v850_write_fpec GPR:$value)]>;

} // Predicates = [HasV850FPU]

//===----------------------------------------------------------------------===//
// Memory Barrier Intrinsic Patterns
//===----------------------------------------------------------------------===//

// SYNCP - Full pipeline synchronization (strongest barrier)
def : Pat<(int_v850_syncp), (SYNCP)>;

// SYNCM - Memory synchronization
def : Pat<(int_v850_syncm), (SYNCM)>;

// SYNCE - Exception synchronization
def : Pat<(int_v850_synce), (SYNCE)>;

//===----------------------------------------------------------------------===//
// Interrupt Control Intrinsic Patterns
//===----------------------------------------------------------------------===//

// DI - Disable interrupts
def : Pat<(int_v850_di), (DI)>;

// EI - Enable interrupts
def : Pat<(int_v850_ei), (EI)>;

//===----------------------------------------------------------------------===//
// Generic System Register Access Patterns
//
// These patterns map llvm.v850.ldsr/stsr intrinsics with immediate regID
// to the corresponding LDSR/STSR instructions with specific system registers.
//===----------------------------------------------------------------------===//

// STSR patterns - Read system register by regID
// i32 @llvm.v850.stsr(i32 regID) -> STSR sysreg, GPR
def : Pat<(int_v850_stsr (i32 0)), (STSR EIPC)>;    // EIPC
def : Pat<(int_v850_stsr (i32 1)), (STSR EIPSW)>;   // EIPSW
def : Pat<(int_v850_stsr (i32 2)), (STSR FEPC)>;    // FEPC
def : Pat<(int_v850_stsr (i32 3)), (STSR FEPSW)>;   // FEPSW
def : Pat<(int_v850_stsr (i32 4)), (STSR ECR)>;     // ECR
def : Pat<(int_v850_stsr (i32 5)), (STSR PSW)>;     // PSW
def : Pat<(int_v850_stsr (i32 20)), (STSR CTPC)>;   // CTPC
def : Pat<(int_v850_stsr (i32 21)), (STSR CTPSW)>;  // CTPSW
def : Pat<(int_v850_stsr (i32 28)), (STSR EIWR)>;   // EIWR
def : Pat<(int_v850_stsr (i32 29)), (STSR FEWR)>;   // FEWR
def : Pat<(int_v850_stsr (i32 31)), (STSR BSEL)>;   // BSEL

// LDSR patterns - Write system register by regID
// void @llvm.v850.ldsr(i32 value, i32 regID) -> LDSR GPR, sysreg
def : Pat<(int_v850_ldsr GPR:$val, (i32 0)), (LDSR GPR:$val, EIPC)>;
def : Pat<(int_v850_ldsr GPR:$val, (i32 1)), (LDSR GPR:$val, EIPSW)>;
def : Pat<(int_v850_ldsr GPR:$val, (i32 2)), (LDSR GPR:$val, FEPC)>;
def : Pat<(int_v850_ldsr GPR:$val, (i32 3)), (LDSR GPR:$val, FEPSW)>;
def : Pat<(int_v850_ldsr GPR:$val, (i32 4)), (LDSR GPR:$val, ECR)>;
def : Pat<(int_v850_ldsr GPR:$val, (i32 5)), (LDSR GPR:$val, PSW)>;
def : Pat<(int_v850_ldsr GPR:$val, (i32 20)), (LDSR GPR:$val, CTPC)>;
def : Pat<(int_v850_ldsr GPR:$val, (i32 21)), (LDSR GPR:$val, CTPSW)>;
def : Pat<(int_v850_ldsr GPR:$val, (i32 28)), (LDSR GPR:$val, EIWR)>;
def : Pat<(int_v850_ldsr GPR:$val, (i32 29)), (LDSR GPR:$val, FEWR)>;
def : Pat<(int_v850_ldsr GPR:$val, (i32 31)), (LDSR GPR:$val, BSEL)>;

//===----------------------------------------------------------------------===//
// MAC/MACU Intrinsic Patterns
//
// Map intrinsics to MAC/MACU instructions.
// The intrinsics use register pairs (hi, lo) for the 64-bit accumulator.
//===----------------------------------------------------------------------===//

// MAC - Signed multiply-accumulate intrinsic
def : Pat<(int_v850_mac GPR:$a, GPR:$b, GPR:$acc_hi, GPR:$acc_lo),
          (MAC GPR:$a, GPR:$b, GPR:$acc_hi, GPR:$acc_lo)>,
      Requires<[HasV850E2M]>;

// MACU - Unsigned multiply-accumulate intrinsic
def : Pat<(int_v850_macu GPR:$a, GPR:$b, GPR:$acc_hi, GPR:$acc_lo),
          (MACU GPR:$a, GPR:$b, GPR:$acc_hi, GPR:$acc_lo)>,
      Requires<[HasV850E2M]>;

//===----------------------------------------------------------------------===//
// SWITCH Intrinsic Pattern (V850E1+)
//
// Maps the llvm.v850.switch intrinsic to the SWITCH instruction.
// The table must immediately follow the SWITCH instruction in memory.
//===----------------------------------------------------------------------===//

// SWITCH - Jump with table look up intrinsic
def : Pat<(int_v850_switch GPR:$index),
          (SWITCH GPR:$index)>,
      Requires<[HasV850E1]>;
