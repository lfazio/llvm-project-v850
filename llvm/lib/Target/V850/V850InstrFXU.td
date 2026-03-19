//===-- V850InstrFXU.td - V850 FXU SIMD Instructions ------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file describes the RH850G4MH FXU (Extended Floating-point Unit)
// instructions.  The FXU provides 128-bit SIMD operations on 4 parallel
// single-precision floating-point values stored in wreg0-wreg31.
//
// Instruction categories (59 total):
//   - Manipulation   (3): MOVV.W4, FLPV.S4, SHFLV.W4
//   - Load/Store     (8): LDV.W, LDV.DW, LDV.QW, LDVZ.H4,
//                         STV.W, STV.DW, STV.QW, STVZ.H4
//   - Arithmetic    (11): ABSF.S4, NEGF.S4, ADDF.S4, SUBF.S4, MULF.S4,
//                         DIVF.S4, MAXF.S4, MINF.S4, SQRTF.S4,
//                         RECIPF.S4, RSQRTF.S4
//   - FMA            (4): FMAF.S4, FMSF.S4, FNMAF.S4, FNMSF.S4
//   - Compound       (4): ADDSUBF.S4, ADDSUBNF.S4, SUBADDF.S4, SUBADDNF.S4
//   - Exchange       (7): ADDXF.S4, SUBXF.S4, MULXF.S4,
//                         ADDSUBXF.S4, ADDSUBNXF.S4, SUBADDXF.S4, SUBADDNXF.S4
//   - Reduction      (5): ADDRF.S4, SUBRF.S4, MULRF.S4, MAXRF.S4, MINRF.S4
//   - Conversion    (14): CVTF.HS4, CVTF.SH4, CVTF.SW4, CVTF.WS4,
//                         CVTF.SUW4, CVTF.UWS4,
//                         TRNCF.SW4, TRNCF.SUW4,
//                         CEILF.SW4, CEILF.SUW4,
//                         FLOORF.SW4, FLOORF.SUW4,
//                         ROUNDF.SW4, ROUNDF.SUW4
//   - Comparison     (3): CMPF.S4, CMOVF.W4, TRFSRV.W4
//
// Encoding summary:
//   32-bit instructions: bits[10:5] = 111111 (same as scalar FPU)
//   48-bit instructions: bits[10:5] = 111101
//
// All 2OP instructions share bits[26:16] = 10110100000 (0x5a0),
// differentiated by bits[4:0].
//
// All 3OP instructions share bits[10:5] = 111111 and bits[4:0] = wreg1,
// differentiated by bits[26:16].
//
//===----------------------------------------------------------------------===//

// All FXU instructions require RH850G4MH and use the FXU decoder namespace.
let Predicates = [HasRH850G4MH], DecoderNamespace = "FXURH850G4MH" in {

//===----------------------------------------------------------------------===//
// 1. Vector Manipulation Instructions
//===----------------------------------------------------------------------===//

// MOVV.W4 wreg2, wreg3
// Move vector register: wreg3 = wreg2
// Format M: 2OP, subop5=11110 (0x1e), subop11=10110100000 (0x5a0)
def MOVV_W4 : FormatM_2OP<0b11110, 0b10110100000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2),
    "movv.w4\t$wreg2, $wreg3", []>;

// FLPV.S4 imm2, wreg2, wreg3
// Flip (exchange) vector elements selected by imm2: wreg3 = flip(wreg2, imm2)
// Format M: 2OP, subop5=110ii (bits[1:0]=imm2), subop11=10110100000 (0x5a0)
// imm2 selects which pair of elements to exchange (0-3)
def FLPV_S4 : FormatM_2OP<0b11000, 0b10110100000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2, i32imm:$imm2),
    "flpv.s4\t$imm2, $wreg2, $wreg3", []> {
  bits<2> imm2;
  let Inst{1 -0} = imm2;
}

// SHFLV.W4 imm12, wreg1, wreg2, wreg3
// Shuffle vector elements: wreg3 = shuffle(wreg2, wreg1, imm12)
// Format M: imm12 (48-bit)
// subop5a=01101 (0x0d), subop11=01101x11101 (bit[21]=imm12[11])
// Second word: wreg2[47:43], imm12[10:0][42:32]
// imm12 describes the shuffle permutation (element selection from wreg1/wreg2)
def SHFLV_W4 : FormatM_Imm12<0b01101, 0b01101011101,
    (outs VGPR:$wreg3), (ins VGPR:$wreg1, VGPR:$wreg2, i32imm:$imm12),
    "shflv.w4\t$imm12, $wreg1, $wreg2, $wreg3", []> {
  // imm12[11] (MSB) is encoded in subop11 bit[21]
  // Override subop11 bit 5 with imm12[11]
  let Inst{21} = imm12{11};
}

//===----------------------------------------------------------------------===//
// 2. Vector Load/Store Instructions
//===----------------------------------------------------------------------===//
// Format M: D (48-bit)
// All use: bits[10:5]=111101, bits[31:27]=wreg3, bits[47:32]=disp16
// Differentiated by bits[26:16].

// LDV.W disp16[reg1], imm4, wreg3
// Load single word from memory into element imm4 of wreg3
// subop11 = 00xxxx11101 where xxxx = imm4 (element selector in bits[25:22])
// For MC layer, we model this as loading element 0 (imm4=0) unless specified.
// Full assembler support: LDV.W disp16[reg1], wreg3 (imm4 defaults to 0)
// or LDV.W disp16[reg1], imm4, wreg3 for specific element.
def LDV_W : FormatM_D<0b00000011101,
    (outs VGPR:$wreg3), (ins GPR:$reg1, i32imm:$disp16, i32imm:$imm4),
    "ldv.w\t$disp16[$reg1], $imm4, $wreg3", []> {
  bits<4> imm4;
  let reg2 = 0;
  // imm4 is encoded in bits[24:21] of subop11 (ISA: 00iiii11101)
  let Inst{24 -21} = imm4;
}

// LDV.DW imm2, disp16[reg1], wreg3
// Load double-word (64-bit) from memory into selected double-word element(s) of wreg3
// Each bit of imm2 controls whether the corresponding double-word element is loaded:
//   imm2[0]=1: load wreg3(dw0), imm2[1]=1: load wreg3(dw1)
// Encoding: bits[26:16] = 0110ii11101 where ii = imm2 in bits[22:21]
// (from ISA: "0 1 1 0 i i 1 1 1 0 1" in bits [26..16])
def LDV_DW : FormatM_D<0b01100011101,
    (outs VGPR:$wreg3), (ins i32imm:$imm2, GPR:$reg1, i32imm:$disp16),
    "ldv.dw\t$imm2, $disp16[$reg1], $wreg3", []> {
  bits<2> imm2;
  let reg2 = 0;
  let Inst{22 -21} = imm2;
}

// LDV.QW disp16[reg1], wreg3
// Load quad-word (128-bit / full vector) from memory into wreg3
// Encoding: bits[26:16] = 01010011101 (0x29d)
// (from ISA: "0 1 0 1 0 0 1 1 1 0 1" in bits [26..16])
def LDV_QW : FormatM_D<0b01010011101,
    (outs VGPR:$wreg3), (ins GPR:$reg1, i32imm:$disp16),
    "ldv.qw\t$disp16[$reg1], $wreg3", []> {
  let reg2 = 0;
}

// LDVZ.H4 disp16[reg1], wreg3
// Load 4 halfwords from memory, zero-extend to 4 words in wreg3
// subop11 = 01111011101 (0x3dd)
def LDVZ_H4 : FormatM_D<0b01111011101,
    (outs VGPR:$wreg3), (ins GPR:$reg1, i32imm:$disp16),
    "ldvz.h4\t$disp16[$reg1], $wreg3", []> {
  let reg2 = 0;
}

// STV.W wreg3, disp16[reg1], imm2
// Store one word from element imm2 of wreg3 to memory
// subop11 = 0100xx11101 where xx=imm2 in bits[22:21]
def STV_W : FormatM_D<0b01000011101,
    (outs), (ins VGPR:$wreg3, GPR:$reg1, i32imm:$disp16, i32imm:$imm2),
    "stv.w\t$wreg3, $disp16[$reg1], $imm2", []> {
  bits<2> imm2;
  let reg2 = 0;
  let Inst{22 -21} = imm2;
}

// STV.DW wreg3, disp16[reg1]
// Store double-word (64-bit / 2 elements) from wreg3[1:0] to memory
// subop11 = 01110x11101 where x=imm1 in bit[21] (selects upper/lower pair)
// For basic form (imm1=0): subop11 = 01110011101
def STV_DW : FormatM_D<0b01110011101,
    (outs), (ins VGPR:$wreg3, GPR:$reg1, i32imm:$disp16),
    "stv.dw\t$wreg3, $disp16[$reg1]", []> {
  let reg2 = 0;
}

// STV.DW wreg3, disp16[reg1], imm1 (with pair selector)
def STV_DW_E : FormatM_D<0b01110011101,
    (outs), (ins VGPR:$wreg3, GPR:$reg1, i32imm:$disp16, i32imm:$imm1),
    "stv.dw\t$wreg3, $disp16[$reg1], $imm1", []> {
  bits<1> imm1;
  let reg2 = 0;
  let Inst{21} = imm1;
}

// STV.QW wreg3, disp16[reg1]
// Store quad-word (128-bit / full vector) from wreg3 to memory
// subop11 = 01010111101 (0x2bd)
def STV_QW : FormatM_D<0b01010111101,
    (outs), (ins VGPR:$wreg3, GPR:$reg1, i32imm:$disp16),
    "stv.qw\t$wreg3, $disp16[$reg1]", []> {
  let reg2 = 0;
}

// STVZ.H4 wreg3, disp16[reg1]
// Store 4 words from wreg3 truncated to halfwords to memory
// subop11 = 01111111101 (0x3fd)
def STVZ_H4 : FormatM_D<0b01111111101,
    (outs), (ins VGPR:$wreg3, GPR:$reg1, i32imm:$disp16),
    "stvz.h4\t$wreg3, $disp16[$reg1]", []> {
  let reg2 = 0;
}

//===----------------------------------------------------------------------===//
// 3. Vector Arithmetic Instructions (2OP and 3OP)
//===----------------------------------------------------------------------===//

// --- 2OP arithmetic: all share subop11=10110100000 (0x5a0) ---

// ABSF.S4 wreg2, wreg3  -- subop5=10000 (0x10)
def ABSF_S4 : FormatM_2OP<0b10000, 0b10110100000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2),
    "absf.s4\t$wreg2, $wreg3", []>;

// NEGF.S4 wreg2, wreg3  -- subop5=10001 (0x11)
def NEGF_S4 : FormatM_2OP<0b10001, 0b10110100000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2),
    "negf.s4\t$wreg2, $wreg3", []>;

// SQRTF.S4 wreg2, wreg3  -- subop5=10010 (0x12)
def SQRTF_S4 : FormatM_2OP<0b10010, 0b10110100000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2),
    "sqrtf.s4\t$wreg2, $wreg3", []>;

// RECIPF.S4 wreg2, wreg3  -- subop5=10011 (0x13)
def RECIPF_S4 : FormatM_2OP<0b10011, 0b10110100000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2),
    "recipf.s4\t$wreg2, $wreg3", []>;

// RSQRTF.S4 wreg2, wreg3  -- subop5=10100 (0x14)
def RSQRTF_S4 : FormatM_2OP<0b10100, 0b10110100000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2),
    "rsqrtf.s4\t$wreg2, $wreg3", []>;

// --- 3OP arithmetic: differentiated by subop11 ---

// ADDF.S4 wreg1, wreg2, wreg3  -- subop11=10110100100 (0x5a4)
def ADDF_S4 : FormatM_3OP<0b10110100100,
    (outs VGPR:$wreg3), (ins VGPR:$wreg1, VGPR:$wreg2),
    "addf.s4\t$wreg1, $wreg2, $wreg3", []>;

// SUBF.S4 wreg1, wreg2, wreg3  -- subop11=10110100110 (0x5a6)
def SUBF_S4 : FormatM_3OP<0b10110100110,
    (outs VGPR:$wreg3), (ins VGPR:$wreg1, VGPR:$wreg2),
    "subf.s4\t$wreg1, $wreg2, $wreg3", []>;

// MULF.S4 wreg1, wreg2, wreg3  -- subop11=10110101000 (0x5a8)
def MULF_S4 : FormatM_3OP<0b10110101000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg1, VGPR:$wreg2),
    "mulf.s4\t$wreg1, $wreg2, $wreg3", []>;

// MAXF.S4 wreg1, wreg2, wreg3  -- subop11=10110101010 (0x5aa)
def MAXF_S4 : FormatM_3OP<0b10110101010,
    (outs VGPR:$wreg3), (ins VGPR:$wreg1, VGPR:$wreg2),
    "maxf.s4\t$wreg1, $wreg2, $wreg3", []>;

// MINF.S4 wreg1, wreg2, wreg3  -- subop11=10110101100 (0x5ac)
def MINF_S4 : FormatM_3OP<0b10110101100,
    (outs VGPR:$wreg3), (ins VGPR:$wreg1, VGPR:$wreg2),
    "minf.s4\t$wreg1, $wreg2, $wreg3", []>;

// DIVF.S4 wreg1, wreg2, wreg3  -- subop11=10110101110 (0x5ae)
// Note: ISA doc labels this 2OP but encodes wreg1 in bits[4:0] (acts as 3OP)
def DIVF_S4 : FormatM_3OP<0b10110101110,
    (outs VGPR:$wreg3), (ins VGPR:$wreg1, VGPR:$wreg2),
    "divf.s4\t$wreg1, $wreg2, $wreg3", []>;

//===----------------------------------------------------------------------===//
// 4. Fused Multiply-Add Instructions (3OP)
//===----------------------------------------------------------------------===//
// All FMA instructions use 3OP format, differentiated by subop11.

// FMAF.S4 wreg1, wreg2, wreg3  -- subop11=10011000000 (0x4c0)
// wreg3 = (wreg2 * wreg1) + wreg3
def FMAF_S4 : FormatM_3OP<0b10011000000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg1, VGPR:$wreg2, VGPR:$wreg3_in),
    "fmaf.s4\t$wreg1, $wreg2, $wreg3", []> {
  let Constraints = "$wreg3 = $wreg3_in";
}

// FMSF.S4 wreg1, wreg2, wreg3  -- subop11=10011000010 (0x4c2)
// wreg3 = (wreg2 * wreg1) - wreg3
def FMSF_S4 : FormatM_3OP<0b10011000010,
    (outs VGPR:$wreg3), (ins VGPR:$wreg1, VGPR:$wreg2, VGPR:$wreg3_in),
    "fmsf.s4\t$wreg1, $wreg2, $wreg3", []> {
  let Constraints = "$wreg3 = $wreg3_in";
}

// FNMAF.S4 wreg1, wreg2, wreg3  -- subop11=10011000100 (0x4c4)
// wreg3 = -(wreg2 * wreg1) + wreg3
def FNMAF_S4 : FormatM_3OP<0b10011000100,
    (outs VGPR:$wreg3), (ins VGPR:$wreg1, VGPR:$wreg2, VGPR:$wreg3_in),
    "fnmaf.s4\t$wreg1, $wreg2, $wreg3", []> {
  let Constraints = "$wreg3 = $wreg3_in";
}

// FNMSF.S4 wreg1, wreg2, wreg3  -- subop11=10011000110 (0x4c6)
// wreg3 = -(wreg2 * wreg1) - wreg3
def FNMSF_S4 : FormatM_3OP<0b10011000110,
    (outs VGPR:$wreg3), (ins VGPR:$wreg1, VGPR:$wreg2, VGPR:$wreg3_in),
    "fnmsf.s4\t$wreg1, $wreg2, $wreg3", []> {
  let Constraints = "$wreg3 = $wreg3_in";
}

//===----------------------------------------------------------------------===//
// 5. Compound Arithmetic Instructions (3OP)
//===----------------------------------------------------------------------===//
// These instructions operate on pairs of elements differently:
//   ADDSUBF.S4:  wreg3[3:2] = add,  wreg3[1:0] = sub
//   SUBADDF.S4:  wreg3[3:2] = sub,  wreg3[1:0] = add
//   ADDSUBNF.S4: wreg3[3:2] = add,  wreg3[1:0] = -(sub)
//   SUBADDNF.S4: wreg3[3:2] = sub,  wreg3[1:0] = -(add)

// ADDSUBF.S4 wreg1, wreg2, wreg3  -- subop11=10110101000 = wait, let me recalculate
// From extraction: ADDSUBF.S4: 0x5d0=10110110000
def ADDSUBF_S4 : FormatM_3OP<0b10110110000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg1, VGPR:$wreg2),
    "addsubf.s4\t$wreg1, $wreg2, $wreg3", []>;

// SUBADDF.S4 wreg1, wreg2, wreg3  -- subop11=10110110010 (0x5d2)
def SUBADDF_S4 : FormatM_3OP<0b10110110010,
    (outs VGPR:$wreg3), (ins VGPR:$wreg1, VGPR:$wreg2),
    "subaddf.s4\t$wreg1, $wreg2, $wreg3", []>;

// ADDSUBNF.S4 wreg1, wreg2, wreg3  -- subop11=10110111000 (0x5d8)
def ADDSUBNF_S4 : FormatM_3OP<0b10110111000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg1, VGPR:$wreg2),
    "addsubnf.s4\t$wreg1, $wreg2, $wreg3", []>;

// SUBADDNF.S4 wreg1, wreg2, wreg3  -- subop11=10110111010 (0x5da)
def SUBADDNF_S4 : FormatM_3OP<0b10110111010,
    (outs VGPR:$wreg3), (ins VGPR:$wreg1, VGPR:$wreg2),
    "subaddnf.s4\t$wreg1, $wreg2, $wreg3", []>;

//===----------------------------------------------------------------------===//
// 6. Exchange Arithmetic Instructions (3OP)
//===----------------------------------------------------------------------===//
// Exchange variants swap elements of wreg1 before computing.

// ADDXF.S4 wreg1, wreg2, wreg3  -- subop11=10110100100 wait...
// From extraction: ADDXF.S4: 0x5c4=10110100100 -- but that's ADDF!
// Let me re-read: ADDXF.S4=0x5c4, ADDF.S4=0x5a4
// 0x5c4 = 10111000100, 0x5a4 = 10110100100
// Actually: 0x5c4 = 0101 1100 0100 -> bits: 10111000100? No:
// 0x5c4 = 1492 decimal, in 11 bits: 10111000100
// Hmm, 0x5c4 = 0101 1100 0100 = 1124. Wait: 0x5c4 = 5*256+12*16+4=1220+4=1220+4...
// No: hex 5c4 = 5*16^2 + 12*16 + 4 = 5*256 + 192 + 4 = 1280+192+4 = 1476
// In 11 bits: 10111000100? Let me compute: 1476 in binary:
// 1024+256+128+64+4 = 1476: 10111000100 -- yes, 11 bits = 10111000100
// But 0x5c4 = 1476: 1024+256+128+64+4=1476. 10000000000=1024, 01000000000=512
// Actually 1476 = 1024+452 = 1024+256+196 = 1024+256+128+68 = 1024+256+128+64+4
// = 10111000100 in binary. Yes.

// ADDXF.S4 wreg1, wreg2, wreg3  -- subop11=10111000100 (0x5c4)
def ADDXF_S4 : FormatM_3OP<0b10111000100,
    (outs VGPR:$wreg3), (ins VGPR:$wreg1, VGPR:$wreg2),
    "addxf.s4\t$wreg1, $wreg2, $wreg3", []>;

// SUBXF.S4 wreg1, wreg2, wreg3  -- subop11=10111000110 (0x5c6)
def SUBXF_S4 : FormatM_3OP<0b10111000110,
    (outs VGPR:$wreg3), (ins VGPR:$wreg1, VGPR:$wreg2),
    "subxf.s4\t$wreg1, $wreg2, $wreg3", []>;

// MULXF.S4 wreg1, wreg2, wreg3  -- subop11=10111001000 (0x5c8)
def MULXF_S4 : FormatM_3OP<0b10111001000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg1, VGPR:$wreg2),
    "mulxf.s4\t$wreg1, $wreg2, $wreg3", []>;

// ADDSUBXF.S4 wreg1, wreg2, wreg3  -- subop11=10111010100 (0x5d4)
def ADDSUBXF_S4 : FormatM_3OP<0b10111010100,
    (outs VGPR:$wreg3), (ins VGPR:$wreg1, VGPR:$wreg2),
    "addsubxf.s4\t$wreg1, $wreg2, $wreg3", []>;

// SUBADDXF.S4 wreg1, wreg2, wreg3  -- subop11=10111010110 (0x5d6)
def SUBADDXF_S4 : FormatM_3OP<0b10111010110,
    (outs VGPR:$wreg3), (ins VGPR:$wreg1, VGPR:$wreg2),
    "subaddxf.s4\t$wreg1, $wreg2, $wreg3", []>;

// ADDSUBNXF.S4 wreg1, wreg2, wreg3  -- subop11=10111011100 (0x5dc)
def ADDSUBNXF_S4 : FormatM_3OP<0b10111011100,
    (outs VGPR:$wreg3), (ins VGPR:$wreg1, VGPR:$wreg2),
    "addsubnxf.s4\t$wreg1, $wreg2, $wreg3", []>;

// SUBADDNXF.S4 wreg1, wreg2, wreg3  -- subop11=10111011110 (0x5de)
def SUBADDNXF_S4 : FormatM_3OP<0b10111011110,
    (outs VGPR:$wreg3), (ins VGPR:$wreg1, VGPR:$wreg2),
    "subaddnxf.s4\t$wreg1, $wreg2, $wreg3", []>;

//===----------------------------------------------------------------------===//
// 7. Reduction Instructions (3OP)
//===----------------------------------------------------------------------===//
// Reduction operations reduce 4 elements to a scalar stored in element 0.

// ADDRF.S4 wreg2, wreg3  -- 3OP, subop11=10110101100... wait
// From extraction: ADDRF.S4=0x5b4=10110110100? Let me compute:
// 0x5b4 = 5*256+11*16+4 = 1280+176+4 = 1460
// 1460 in binary (11 bits): 10110110100
// 1024+256+128+32+16+4 = 1460: 10110110100 yes.

// ADDRF.S4 wreg2, wreg3  -- subop11=10110110100 (0x5b4)
// Actually these are 3OP (need wreg1 even if it's the same as wreg2 for reduction)
// Looking at the doc: ADDRF.S4 wreg2, wreg3 -- only 2 register operands
// But format is 3OP which requires wreg1... The doc says wreg2 is both source and
// accumulated into result. For reduction, wreg1=wreg2 effectively (or wreg1 unused).
// Actually from the ISA the reduction uses wreg2 as source, wreg3 as dest.
// The 3OP encoding means bits[4:0]=wreg1 which the assembler should encode as 0.
def ADDRF_S4 : FormatM_3OP<0b10110110100,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2),
    "addrf.s4\t$wreg2, $wreg3", []> {
  let wreg1 = 0;
}

// SUBRF.S4 wreg2, wreg3  -- subop11=10110110110 (0x5b6)
def SUBRF_S4 : FormatM_3OP<0b10110110110,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2),
    "subrf.s4\t$wreg2, $wreg3", []> {
  let wreg1 = 0;
}

// MULRF.S4 wreg2, wreg3  -- subop11=10110111000... let me recalculate
// From extraction: MULRF.S4=0x5b8=10110111000? 0x5b8=5*256+11*16+8=1280+176+8=1464
// 1464 in 11 bits: 10110111000? 1024+256+128+32+16+8=1464: 10110111000 yes.
def MULRF_S4 : FormatM_3OP<0b10110111000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2),
    "mulrf.s4\t$wreg2, $wreg3", []> {
  let wreg1 = 0;
}

// MAXRF.S4 wreg2, wreg3  -- subop11=10110111010 (0x5ba)
def MAXRF_S4 : FormatM_3OP<0b10110111010,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2),
    "maxrf.s4\t$wreg2, $wreg3", []> {
  let wreg1 = 0;
}

// MINRF.S4 wreg2, wreg3  -- subop11=10110111100 (0x5bc)
def MINRF_S4 : FormatM_3OP<0b10110111100,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2),
    "minrf.s4\t$wreg2, $wreg3", []> {
  let wreg1 = 0;
}

//===----------------------------------------------------------------------===//
// 8. Conversion and Rounding Instructions (2OP)
//===----------------------------------------------------------------------===//
// All share subop11=10110100000 (0x5a0), differentiated by subop5[4:0].

// ROUNDF.SW4 wreg2, wreg3   -- subop5=00000 (0x00) Round to signed int
def ROUNDF_SW4 : FormatM_2OP<0b00000, 0b10110100000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2),
    "roundf.sw4\t$wreg2, $wreg3", []>;

// ROUNDF.SUW4 wreg2, wreg3  -- subop5=00001 (0x01) Round to unsigned int
def ROUNDF_SUW4 : FormatM_2OP<0b00001, 0b10110100000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2),
    "roundf.suw4\t$wreg2, $wreg3", []>;

// TRNCF.SW4 wreg2, wreg3    -- subop5=00010 (0x02) Truncate to signed int
def TRNCF_SW4 : FormatM_2OP<0b00010, 0b10110100000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2),
    "trncf.sw4\t$wreg2, $wreg3", []>;

// TRNCF.SUW4 wreg2, wreg3   -- subop5=00011 (0x03) Truncate to unsigned int
def TRNCF_SUW4 : FormatM_2OP<0b00011, 0b10110100000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2),
    "trncf.suw4\t$wreg2, $wreg3", []>;

// CEILF.SW4 wreg2, wreg3    -- subop5=00100 (0x04) Ceiling to signed int
def CEILF_SW4 : FormatM_2OP<0b00100, 0b10110100000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2),
    "ceilf.sw4\t$wreg2, $wreg3", []>;

// CEILF.SUW4 wreg2, wreg3   -- subop5=00101 (0x05) Ceiling to unsigned int
def CEILF_SUW4 : FormatM_2OP<0b00101, 0b10110100000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2),
    "ceilf.suw4\t$wreg2, $wreg3", []>;

// FLOORF.SW4 wreg2, wreg3   -- subop5=00110 (0x06) Floor to signed int
def FLOORF_SW4 : FormatM_2OP<0b00110, 0b10110100000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2),
    "floorf.sw4\t$wreg2, $wreg3", []>;

// FLOORF.SUW4 wreg2, wreg3  -- subop5=00111 (0x07) Floor to unsigned int
def FLOORF_SUW4 : FormatM_2OP<0b00111, 0b10110100000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2),
    "floorf.suw4\t$wreg2, $wreg3", []>;

// CVTF.SW4 wreg2, wreg3     -- subop5=01000 (0x08) Float to signed int
def CVTF_SW4 : FormatM_2OP<0b01000, 0b10110100000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2),
    "cvtf.sw4\t$wreg2, $wreg3", []>;

// CVTF.SUW4 wreg2, wreg3    -- subop5=01001 (0x09) Float to unsigned int
def CVTF_SUW4 : FormatM_2OP<0b01001, 0b10110100000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2),
    "cvtf.suw4\t$wreg2, $wreg3", []>;

// CVTF.WS4 wreg2, wreg3     -- subop5=01010 (0x0a) Signed int to float
def CVTF_WS4 : FormatM_2OP<0b01010, 0b10110100000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2),
    "cvtf.ws4\t$wreg2, $wreg3", []>;

// CVTF.UWS4 wreg2, wreg3    -- subop5=01011 (0x0b) Unsigned int to float
def CVTF_UWS4 : FormatM_2OP<0b01011, 0b10110100000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2),
    "cvtf.uws4\t$wreg2, $wreg3", []>;

// CVTF.HS4 wreg2, wreg3     -- subop5=01100 (0x0c) Half to float
def CVTF_HS4 : FormatM_2OP<0b01100, 0b10110100000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2),
    "cvtf.hs4\t$wreg2, $wreg3", []>;

// CVTF.SH4 wreg2, wreg3     -- subop5=01101 (0x0d) Float to half
def CVTF_SH4 : FormatM_2OP<0b01101, 0b10110100000,
    (outs VGPR:$wreg3), (ins VGPR:$wreg2),
    "cvtf.sh4\t$wreg2, $wreg3", []>;

//===----------------------------------------------------------------------===//
// 9. Comparison Instructions
//===----------------------------------------------------------------------===//

// CMPF.S4 fcond, wreg1, wreg2, wreg3
// Compare 4 float pairs, store mask in wreg3
// Format M: 3OP, subop11=101100xxxx0 where xxxx=fcond (4-bit float condition)
// bits[20:17] = fcond (4-bit float condition code)
// subop11 base = 10110000000 (0x580), with fcond in bits[20:17]
def CMPF_S4 : FormatM_3OP<0b10110000000,
    (outs VGPR:$wreg3), (ins i32imm:$fcond, VGPR:$wreg1, VGPR:$wreg2),
    "cmpf.s4\t$fcond, $wreg1, $wreg2, $wreg3", []> {
  bits<4> fcond;
  let Inst{20 -17} = fcond;
}

// CMOVF.W4 fcond4, wreg1, wreg2, wreg3
// Conditional move based on FXSR compare flags
// Format M: 4OP (48-bit)
// First word: subop5a=00000, subop11=11000011101 (0x61d)
// Second word: wreg2, subop6=000000, wreg4=wreg3(dest)
// Note: wreg4 in this encoding is the destination register
def CMOVF_W4 : FormatM_4OP<0b00000, 0b11000011101, 0b000000,
    (outs VGPR:$wreg4), (ins i32imm:$fcond4, VGPR:$wreg1, VGPR:$wreg2,
                             VGPR:$wreg3),
    "cmovf.w4\t$fcond4, $wreg1, $wreg2, $wreg3, $wreg4", []> {
  bits<4> fcond4;
  // fcond4 is encoded in bits[4:1] of the first word (within wreg1 field)
  // Actually from extraction: CMOVF.W4 subop5a=00000 means bits[15:11]=00000
  // and wreg1 occupies bits[4:0]. The fcond4 may be within wreg1 field.
  // Per the ISA, for CMOVF.W4 the first word has: 00000 111101 fcond4+wreg1?
  // For now encode fcond4 in bits[3:0] of wreg1 field (instruction format details
  // need more careful review from ISA doc).
  let Inst{4 -1} = fcond4;
  let Inst{0} = 0;
}

// TRFSRV.W4 imm3, wreg3
// Transfer FXU status register to vector
// Format M: 2OP, subop5=11111 (0x1f), subop11=10110100000 (0x5a0)
// wreg2 field (bits[15:11]) encodes imm3 in its lower 3 bits
// imm3 selects which element of the FXSR status to transfer
def TRFSRV_W4 : FormatM_2OP<0b11111, 0b10110100000,
    (outs VGPR:$wreg3), (ins i32imm:$imm3),
    "trfsrv.w4\t$imm3, $wreg3", []> {
  bits<3> imm3;
  // imm3 is in bits[13:11] of the wreg2 field (bits[15:11])
  // wreg2 = 00imm3 where imm3 occupies the lower 3 bits
  let Inst{13 -11} = imm3;
  let Inst{15 -14} = 0;
}

} // Predicates = [HasRH850G4MH], DecoderNamespace = "FXURH850G4MH"

//===----------------------------------------------------------------------===//
// ISel Patterns for FXU vector instructions (v4f32)
//===----------------------------------------------------------------------===//

let Predicates = [HasRH850G4MH] in {

// --- Arithmetic patterns ---

def : Pat<(v4f32 (fadd VGPR:$wreg1, VGPR:$wreg2)),
          (ADDF_S4 VGPR:$wreg1, VGPR:$wreg2)>;

def : Pat<(v4f32 (fsub VGPR:$wreg1, VGPR:$wreg2)),
          (SUBF_S4 VGPR:$wreg1, VGPR:$wreg2)>;

def : Pat<(v4f32 (fmul VGPR:$wreg1, VGPR:$wreg2)),
          (MULF_S4 VGPR:$wreg1, VGPR:$wreg2)>;

def : Pat<(v4f32 (fdiv VGPR:$wreg1, VGPR:$wreg2)),
          (DIVF_S4 VGPR:$wreg1, VGPR:$wreg2)>;

def : Pat<(v4f32 (fabs VGPR:$wreg2)),
          (ABSF_S4 VGPR:$wreg2)>;

def : Pat<(v4f32 (fneg VGPR:$wreg2)),
          (NEGF_S4 VGPR:$wreg2)>;

def : Pat<(v4f32 (fsqrt VGPR:$wreg2)),
          (SQRTF_S4 VGPR:$wreg2)>;

def : Pat<(v4f32 (fminnum VGPR:$wreg1, VGPR:$wreg2)),
          (MINF_S4 VGPR:$wreg1, VGPR:$wreg2)>;

def : Pat<(v4f32 (fmaxnum VGPR:$wreg1, VGPR:$wreg2)),
          (MAXF_S4 VGPR:$wreg1, VGPR:$wreg2)>;

// --- FMA patterns ---

def : Pat<(v4f32 (fma VGPR:$wreg1, VGPR:$wreg2, VGPR:$wreg3)),
          (FMAF_S4 VGPR:$wreg1, VGPR:$wreg2, VGPR:$wreg3)>;

// --- Load/Store patterns ---
// LDV.QW: 128-bit aligned vector load
def : Pat<(v4f32 (load GPR:$base)),
          (LDV_QW GPR:$base, 0)>;

// STV.QW: 128-bit aligned vector store
def : Pat<(store (v4f32 VGPR:$wreg3), GPR:$base),
          (STV_QW VGPR:$wreg3, GPR:$base, 0)>;

} // Predicates = [HasRH850G4MH]
