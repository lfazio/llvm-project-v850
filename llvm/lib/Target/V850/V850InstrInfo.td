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
