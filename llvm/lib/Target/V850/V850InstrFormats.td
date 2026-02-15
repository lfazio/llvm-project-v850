//===-- V850InstrFormats.td - V850 Instruction Formats ----*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file describes the V850 instruction formats.
//
// V850 has 16-bit and 32-bit instruction formats.
// Format I-IV are 16-bit, Format V-X are 32-bit.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// V850 Instruction Base Class
//===----------------------------------------------------------------------===//

class V850Inst<dag outs, dag ins, string asmstr, list<dag> pattern>
    : Instruction {
  field bits<32> Inst;
  field bits<32> SoftFail = 0;

  let Namespace = "V850";
  let Size = 2;  // Default to 16-bit, 32-bit instructions override

  dag OutOperandList = outs;
  dag InOperandList = ins;
  let AsmString = asmstr;
  let Pattern = pattern;
}

// 16-bit instruction base class
class V850Inst16<dag outs, dag ins, string asmstr, list<dag> pattern>
    : V850Inst<outs, ins, asmstr, pattern> {
  let Size = 2;
}

// 32-bit instruction base class
class V850Inst32<dag outs, dag ins, string asmstr, list<dag> pattern>
    : V850Inst<outs, ins, asmstr, pattern> {
  let Size = 4;
}

// 48-bit instruction base class (V850E2+)
// These instructions use 32-bit displacements and require a separate
// Inst field size since the base class only has 32 bits.
class V850Inst48<dag outs, dag ins, string asmstr, list<dag> pattern>
    : Instruction {
  field bits<48> Inst;
  field bits<48> SoftFail = 0;

  let Namespace = "V850";
  let Size = 6;

  dag OutOperandList = outs;
  dag InOperandList = ins;
  let AsmString = asmstr;
  let Pattern = pattern;
}

// Pseudo instruction class
class V850Pseudo<dag outs, dag ins, string asmstr, list<dag> pattern>
    : V850Inst<outs, ins, asmstr, pattern> {
  let isPseudo = 1;
  let isCodeGenOnly = 1;
}

//===----------------------------------------------------------------------===//
// Format I: Register-Register (16-bit)
// Bits: 15-11 = reg2, 10-5 = opcode, 4-0 = reg1
//===----------------------------------------------------------------------===//

class FormatI<bits<6> opcode, dag outs, dag ins, string asmstr,
              list<dag> pattern>
    : V850Inst16<outs, ins, asmstr, pattern> {
  bits<5> reg1;
  bits<5> reg2;

  let Inst{15-11} = reg2;
  let Inst{10-5}  = opcode;
  let Inst{4-0}   = reg1;
}

//===----------------------------------------------------------------------===//
// Format II: Immediate-Register (16-bit)
// Bits: 15-11 = reg2, 10-5 = opcode, 4-0 = imm5
//===----------------------------------------------------------------------===//

class FormatII<bits<6> opcode, dag outs, dag ins, string asmstr,
               list<dag> pattern>
    : V850Inst16<outs, ins, asmstr, pattern> {
  bits<5> imm5;
  bits<5> reg2;

  let Inst{15-11} = reg2;
  let Inst{10-5}  = opcode;
  let Inst{4-0}   = imm5;
}

//===----------------------------------------------------------------------===//
// Format II-IMM6: Immediate-Register with 6-bit immediate (16-bit)
// Bits: 15-11 = reg2 (fixed to 0), 10-6 = opcode (5 bits), 5-0 = imm6
// Variant of Format II for instructions needing 6-bit immediate (CALLT)
//===----------------------------------------------------------------------===//

class FormatII_IMM6<bits<5> opcode, dag outs, dag ins, string asmstr,
                    list<dag> pattern>
    : V850Inst16<outs, ins, asmstr, pattern> {
  bits<6> imm6;

  let Inst{15-11} = 0;              // reg2 = 0
  let Inst{10-6}  = opcode;
  let Inst{5-0}   = imm6;
}

//===----------------------------------------------------------------------===//
// Format III: Conditional Branch (16-bit)
// Bits: 15-11 = disp[8:4], 10-7 = opcode, 6-4 = disp[3:1], 3-0 = cond
//===----------------------------------------------------------------------===//

class FormatIII<bits<4> opcode, dag outs, dag ins, string asmstr,
                list<dag> pattern>
    : V850Inst16<outs, ins, asmstr, pattern> {
  bits<8> disp9;  // Half-displacement (encoder shifts val >> 1)
  bits<4> cond;

  let Inst{15-11} = disp9{7-3};
  let Inst{10-7}  = opcode;
  let Inst{6-4}   = disp9{2-0};
  let Inst{3-0}   = cond;
}

//===----------------------------------------------------------------------===//
// Format IV: Short Load/Store (16-bit)
// Bits: 15-11 = reg2, 10-7 = opcode, 6-0 = disp7 (or 6-1 = disp6, 0 = sub-op)
//===----------------------------------------------------------------------===//

class FormatIV<bits<4> opcode, dag outs, dag ins, string asmstr,
               list<dag> pattern>
    : V850Inst16<outs, ins, asmstr, pattern> {
  bits<5> reg2;
  bits<7> disp7;

  let Inst{15-11} = reg2;
  let Inst{10-7}  = opcode;
  let Inst{6-0}   = disp7;
}

//===----------------------------------------------------------------------===//
// Format IV-E1: Short Load/Store (V850E1+, 16-bit)
// Bits: 15-11 = reg2, 10-4 = opcode (7 bits), 3-0 = disp4
// Used for: SLD.BU, SLD.HU (V850E1 and above)
// For halfword-aligned loads (SLD.HU), the instruction overrides disp4
// to encode disp5{4-1} (byte offset / 2).
//===----------------------------------------------------------------------===//

class FormatIV_E1<bits<7> opcode, dag outs, dag ins, string asmstr,
                  list<dag> pattern>
    : V850Inst16<outs, ins, asmstr, pattern> {
  bits<5> reg2;
  bits<4> disp4;

  let Inst{15-11} = reg2;
  let Inst{10-4}  = opcode;
  let Inst{3-0}   = disp4;
}

//===----------------------------------------------------------------------===//
// Format V: Jump (32-bit)
// First halfword: 15-11 = reg2, 10-6 = opcode[5:1], 5-0 = disp22[5:0]
// Second halfword: 31-17 = disp22[21:7], 16 = disp22[6]
//===----------------------------------------------------------------------===//

class FormatV<bits<6> opcode, dag outs, dag ins, string asmstr,
              list<dag> pattern>
    : V850Inst32<outs, ins, asmstr, pattern> {
  bits<5> reg2;
  bits<22> disp22;

  let Inst{15-11} = reg2;
  let Inst{10-6}  = opcode{5-1};
  let Inst{5-0}   = disp22{5-0};
  let Inst{31-17} = disp22{21-7};
  let Inst{16}    = disp22{6};
}

//===----------------------------------------------------------------------===//
// Format VI: 3-operand (32-bit)
// First halfword: 15-11 = reg2, 10-5 = opcode, 4-0 = reg1
// Second halfword: 31-16 = imm16
//===----------------------------------------------------------------------===//

class FormatVI<bits<6> opcode, dag outs, dag ins, string asmstr,
               list<dag> pattern>
    : V850Inst32<outs, ins, asmstr, pattern> {
  bits<5> reg1;
  bits<5> reg2;
  bits<16> imm16;

  let Inst{15-11} = reg2;
  let Inst{10-5}  = opcode;
  let Inst{4-0}   = reg1;
  let Inst{31-16} = imm16;
}

//===----------------------------------------------------------------------===//
// Format VII: 32-bit Load/Store (32-bit)
// First halfword: 15-11 = reg2, 10-5 = opcode, 4-0 = reg1
// Second halfword: 31-17 = disp16[15:1], 16 = disp16[0] (or sub-op)
//===----------------------------------------------------------------------===//

class FormatVII<bits<6> opcode, dag outs, dag ins, string asmstr,
                list<dag> pattern>
    : V850Inst32<outs, ins, asmstr, pattern> {
  bits<5> reg1;
  bits<5> reg2;
  bits<16> disp16;

  let Inst{15-11} = reg2;
  let Inst{10-5}  = opcode;
  let Inst{4-0}   = reg1;
  let Inst{31-17} = disp16{15-1};
  let Inst{16}    = disp16{0};
}

//===----------------------------------------------------------------------===//
// Format VIII: Bit Manipulation (32-bit)
// First halfword: 15-14 = sub-op, 13-11 = bit#3, 10-5 = opcode, 4-0 = reg1
// Second halfword: 31-16 = disp16
//===----------------------------------------------------------------------===//

class FormatVIII<bits<6> opcode, bits<2> subop, dag outs, dag ins,
                 string asmstr, list<dag> pattern>
    : V850Inst32<outs, ins, asmstr, pattern> {
  bits<3> bit3;
  bits<5> reg1;
  bits<16> disp16;

  let Inst{15-14} = subop;
  let Inst{13-11} = bit3;
  let Inst{10-5}  = opcode;
  let Inst{4-0}   = reg1;
  let Inst{31-16} = disp16;
}

//===----------------------------------------------------------------------===//
// Format IX: Extended 1 (32-bit)
// First halfword: 15-11 = reg2, 10-5 = 111111 (extended opcode), 4-0 = reg1
// Second halfword: 31-27 = RFU(0), 26-21 = sub-op, 20-16 = RFU(0)
//===----------------------------------------------------------------------===//

class FormatIX<bits<6> opcode, bits<6> subop, dag outs, dag ins,
               string asmstr, list<dag> pattern>
    : V850Inst32<outs, ins, asmstr, pattern> {
  bits<5> reg1;
  bits<5> reg2;

  let Inst{15-11} = reg2;
  let Inst{10-5}  = opcode;       // Extended opcode
  let Inst{4-0}   = reg1;
  let Inst{31-27} = 0;              // RFU
  let Inst{26-21} = subop;
  let Inst{20-16} = 0;              // RFU
}

// Format IX with selID: LDSR/STSR with group specification (RH850G3M+)
// Same as FormatIX but bits 20-16 encode selID (register group/bank)
// Marked isCodeGenOnly because selID in bits 20-16 creates decoder conflicts
// with all FormatIX instructions. Disassembly handled by custom decoder in
// V850Disassembler.cpp. Assembly matching works via the AsmMatcher tables.
class FormatIX_sel<bits<6> opcode, bits<6> subop, dag outs, dag ins,
                   string asmstr, list<dag> pattern>
    : V850Inst32<outs, ins, asmstr, pattern> {
  bits<5> reg1;
  bits<5> reg2;
  bits<5> selID;

  let Inst{15-11} = reg2;
  let Inst{10-5}  = opcode;       // Extended opcode
  let Inst{4-0}   = reg1;
  let Inst{31-27} = 0;
  let Inst{26-21} = subop;
  let Inst{20-16} = selID;

  let isCodeGenOnly = 1;
}

//===----------------------------------------------------------------------===//
// Format X: Extended 2 (32-bit)
// First halfword: 15-13 = RFU(0), 12-11 = sub-op[1:0], 10-5 = opcode, 4-0 = imm/vector
// Second halfword: 31-27 = RFU(0), 26-21 = sub-op, 20-16 = RFU(0)
//===----------------------------------------------------------------------===//

class FormatX<bits<6> opcode, bits<6> subop, dag outs, dag ins,
              string asmstr, list<dag> pattern>
    : V850Inst32<outs, ins, asmstr, pattern> {
  bits<5> vector;

  let Inst{15-13} = 0;              // RFU
  let Inst{12-11} = subop{1-0};
  let Inst{10-5}  = opcode;
  let Inst{4-0}   = vector;
  let Inst{31-27} = 0;              // RFU
  let Inst{26-21} = subop;
  let Inst{20-16} = 0;              // RFU
}

//===----------------------------------------------------------------------===//
// Format XI: Extended 3-operand reg-reg-reg (32-bit)
// First halfword: 15-11 = reg2, 10-5 = 111111, 4-0 = reg1
// Second halfword: 31-27 = reg3, 26-21 = sub-op, 20-16 = subid
// Used for: MUL, MULU, DIV, DIVU, BSH, BSW, HSW, CMOV, ADF, SBF, etc.
//
// Notes:
// - For 2-operand instructions (BSH, BSW, HSW, SCH*): use "let reg1 = 0"
// - For conditional operations (CMOV, ADF, SBF): subid encodes {cond, 0}
//===----------------------------------------------------------------------===//

class FormatXI<bits<6> opcode, bits<6> subop, bits<5> subid, dag outs, dag ins,
               string asmstr, list<dag> pattern>
    : V850Inst32<outs, ins, asmstr, pattern> {
  bits<5> reg1;
  bits<5> reg2;
  bits<5> reg3;

  let Inst{15-11} = reg2;
  let Inst{10-5}  = opcode;       // Extended opcode
  let Inst{4-0}   = reg1;
  let Inst{31-27} = reg3;
  let Inst{26-21} = subop;
  let Inst{20-16} = subid;
}

//===----------------------------------------------------------------------===//
// Format XI-IMM: Extended 3-operand with 9-bit immediate (32-bit)
// First halfword: 15-11 = reg2, 10-5 = 111111, 4-0 = imm9[4:0]
// Second halfword: 31-27 = reg3, 26-21 = sub-op, 20-17 = imm9[8:5], 16 = 0
// Used for: MUL imm9, MULU imm9
//===----------------------------------------------------------------------===//

class FormatXI_IMM9<bits<6> opcode, bits<6> subop, dag outs, dag ins,
                    string asmstr, list<dag> pattern>
    : V850Inst32<outs, ins, asmstr, pattern> {
  bits<9> imm9;
  bits<5> reg2;
  bits<5> reg3;

  let Inst{15-11} = reg2;
  let Inst{10-5}  = opcode;       // Extended opcode
  let Inst{4-0}   = imm9{4-0};      // imm9[4:0]
  let Inst{31-27} = reg3;
  let Inst{26-21} = subop;
  let Inst{20-17} = imm9{8-5};      // imm9[8:5]
  let Inst{16}    = 0;
}

//===----------------------------------------------------------------------===//
// Format XII: Extended 3-operand imm-reg-reg (32-bit)
// First halfword: 15-11 = reg2, 10-5 = 111111, 4-0 = imm5
// Second halfword: 31-27 = reg3, 26-21 = sub-op, 20-17 = cond, 16 = 0
// Used for: CMOV with immediate
//===----------------------------------------------------------------------===//

class FormatXII<bits<6> opcode, bits<6> subop, dag outs, dag ins, string asmstr,
                     list<dag> pattern>
    : V850Inst32<outs, ins, asmstr, pattern> {
  bits<5> imm5;
  bits<5> reg2;
  bits<5> reg3;
  bits<4> cond;

  let Inst{15-11} = reg2;
  let Inst{10-5}  = opcode;       // Extended opcode
  let Inst{4-0}   = imm5;
  let Inst{31-27} = reg3;
  let Inst{26-21} = subop;
  let Inst{20-17} = cond;
  let Inst{16}    = 0;
}

// Note: For conditional operations with extended opcode, use FormatXII with
// opcode=0b111111 instead of a separate class.

//===----------------------------------------------------------------------===//
// Format XIII: PREPARE/DISPOSE (32-bit)
// First halfword: 15-11 = 00000, 10-6 = 11001, 5-1 = imm5, 0 = list12[0]
// Second halfword: 31-21 = list12[11:1], 20-16 = reg1 (or 00000 for PREPARE)
// Used for: PREPARE, DISPOSE
//===----------------------------------------------------------------------===//

class FormatXIII<bits<5> opcode, dag outs, dag ins, string asmstr, list<dag> pattern>
    : V850Inst32<outs, ins, asmstr, pattern> {
  bits<5> imm5;
  bits<12> list12;
  bits<5> reg1;

  let Inst{15-11} = 0;              // Fixed
  let Inst{10-6}  = opcode;        // PREPARE/DISPOSE opcode
  let Inst{5-1}   = imm5;
  let Inst{0}     = list12{0};      // list12 bit 0 (r30)
  let Inst{31-21} = list12{11-1};   // list12 bits 11:1
  let Inst{20-16} = reg1;
}

// Note: For PREPARE/DISPOSE without jump register, use FormatXIII with
// "let reg1 = 0" constraint instead of a separate class.

//===----------------------------------------------------------------------===//
// Format VI-E1: 48-bit MOV with 32-bit immediate (V850E1+)
// Used for: MOV imm32, reg1
// First halfword:  15-11 = 0, 10-5 = opcode (110001), 4-0 = reg1
// Second halfword: 31-16 = imm32[15:0]
// Third halfword:  47-32 = imm32[31:16]
//===----------------------------------------------------------------------===//

class FormatVI_E1<bits<6> opcode, dag outs, dag ins, string asmstr, list<dag> pattern>
    : V850Inst48<outs, ins, asmstr, pattern> {
  bits<5> reg1;
  bits<32> imm32;

  let Inst{15-11} = 0;                // reg2 field (must be 0)
  let Inst{10-5}  = opcode;
  let Inst{4-0}   = reg1;
  let Inst{31-16} = imm32{15-0};      // imm32[15:0]
  let Inst{47-32} = imm32{31-16};     // imm32[31:16]
}

//===----------------------------------------------------------------------===//
// Format VI-E2: 48-bit Jump with 32-bit displacement (V850E2+)
// Used for: JARL disp32, JMP disp32, JR disp32
// First halfword:  15-11 = reg2 (unused, set to 0), 10-5 = opcode, 4-0 = reg1
// Second halfword: 31-17 = disp32[15:1], 16 = disp32[0]
// Third halfword:  47-32 = disp32[31:16]
//===----------------------------------------------------------------------===//

class FormatVI_E2<bits<6> opcode, dag outs, dag ins, string asmstr, list<dag> pattern>
    : V850Inst48<outs, ins, asmstr, pattern> {
  bits<5> reg1;
  bits<32> disp32;

  let Inst{15-11} = 0;                // reg2 field (unused)
  let Inst{10-5}  = opcode;
  let Inst{4-0}   = reg1;
  let Inst{16}    = disp32{0};        // disp32 bit 0
  let Inst{31-17} = disp32{15-1};     // disp32[15:1]
  let Inst{47-32} = disp32{31-16};    // disp32[31:16]
}

//===----------------------------------------------------------------------===//
// Format F:I - FPU Instructions (32-bit) - V850E2M+
//
// FPU instructions use Format F:I with:
// First halfword:  15-11 = reg2, 10-5 = 111111 (FPU opcode), 4-0 = reg1
// Second halfword: 31-27 = reg3, 26-16 = sub-opcode/category/type fields
//
// Single-precision: uses all 5 bits of registers
// Double-precision: uses even registers (bit 0 = 0), uses pairs {rN+1, rN}
//
// Sub-opcode encoding varies by instruction type:
// - Arithmetic (ADDF/SUBF/MULF/DIVF): bits 26=1, 25-23=000, 22-21=11, 20-17=subop
// - 2-operand (ABSF/NEGF/SQRTF): bits 26=1, 25-23=000, 22-21=10, 20-17=subop
// - Comparison (CMPF): bits 26=1, 25-23=000, 22-21=0F, 20-17=fff0 (fcbit)
// - Conversion: various category/type combinations
//===----------------------------------------------------------------------===//


//===----------------------------------------------------------------------===//
// Format F:I - FPU Instructions (32-bit)
// All FPU instructions share the 111111 opcode in bits 10-5
//
// Layout: reg2[15:11] | 111111[10:5] | reg1/subop2[4:0] |
//         reg3/fcond[31:27] | bit26 | category[25:23] | type[22:21] |
//         subop[20:17] | bit16
//===----------------------------------------------------------------------===//

// Base class for all FPU instructions (Format F:I)
class FormatFI<dag outs, dag ins, string asmstr, list<dag> pattern>
    : V850Inst32<outs, ins, asmstr, pattern> {
  // Common FPU opcode in bits 10-5
  let Inst{10-5} = 0b111111;
}

// FPU 3-operand instructions: reg3 = reg2 op reg1
// Used for: ADDF, SUBF, MULF, DIVF, MAXF, MINF
class FormatFPU_RRR<bits<4> subop, dag outs, dag ins, string asmstr,
                    list<dag> pattern>
    : FormatFI<outs, ins, asmstr, pattern> {
  bits<5> reg1;
  bits<5> reg2;
  bits<5> reg3;

  let Inst{15-11} = reg2;
  let Inst{4-0}   = reg1;
  let Inst{31-27} = reg3;
  let Inst{26}    = 1;
  let Inst{25-23} = 0b000;            // Category
  let Inst{22-21} = 0b11;             // Type (arithmetic)
  let Inst{20-17} = subop;
  let Inst{16}    = 0;
}

// FPU 2-operand instructions: reg3 = op(reg2)
// Used for: ABSF, NEGF, SQRTF, RECIPF, RSQRTF
class FormatFPU_RR<bits<4> subop, dag outs, dag ins, string asmstr,
                   list<dag> pattern>
    : FormatFI<outs, ins, asmstr, pattern> {
  bits<5> reg2;
  bits<5> reg3;

  let Inst{15-11} = reg2;
  let Inst{4-0}   = 0;                // reg1 unused
  let Inst{31-27} = reg3;
  let Inst{26}    = 1;
  let Inst{25-23} = 0b000;            // Category
  let Inst{22-21} = 0b10;             // Type (2-operand)
  let Inst{20-17} = subop;
  let Inst{16}    = 0;
}

// FPU 4-operand instructions: reg4 = (reg2 * reg1) +/- reg3
// Used for: MADDF.S, MSUBF.S, NMADDF.S, NMSUBF.S
// reg4 is encoded across bits 26 and 20-17
class FormatFPU_RRRR<bits<2> subop, dag outs, dag ins, string asmstr,
                     list<dag> pattern>
    : FormatFI<outs, ins, asmstr, pattern> {
  bits<5> reg1;
  bits<5> reg2;
  bits<5> reg3;
  bits<5> reg4;

  let Inst{15-11} = reg2;
  let Inst{4-0}   = reg1;
  let Inst{31-27} = reg3;
  let Inst{26}    = reg4{4};          // reg4 bit 4
  let Inst{25-23} = 0b101;            // Category for MADD
  let Inst{22-21} = subop;            // 00=MADDF, 01=MSUBF, 10=NMADDF, 11=NMSUBF
  let Inst{20-17} = reg4{3-0};        // reg4 bits 3-0
  let Inst{16}    = 0;
}

// FPU conversion/rounding instructions: reg3 = convert(reg2)
// The category and type bits vary based on source/dest types
// subop2 encodes source type, subop encodes destination type
class FormatFPU_CVT<bits<5> subop2, bits<3> category, bits<2> type, bits<4> subop,
                    dag outs, dag ins, string asmstr, list<dag> pattern>
    : FormatFI<outs, ins, asmstr, pattern> {
  bits<5> reg2;
  bits<5> reg3;

  let Inst{15-11} = reg2;
  let Inst{4-0}   = subop2;           // Additional sub-opcode
  let Inst{31-27} = reg3;
  let Inst{26}    = 1;
  let Inst{25-23} = category;
  let Inst{22-21} = type;
  let Inst{20-17} = subop;            // Sub-operation code
  let Inst{16}    = 0;
}

// TRFSR - Transfer floating-point status to PSW.Z
// Encoding: 00000 111111 00000 | 00000 1 000 00 0fff 0
// Where fff = fcbit (3 bits) in bits 19-17, bit 20 = 0
class FormatFPU_TRFSR<dag outs, dag ins, string asmstr, list<dag> pattern>
    : FormatFI<outs, ins, asmstr, pattern> {
  bits<3> fcbit;

  let Inst{15-11} = 0;
  let Inst{4-0}   = 0;
  let Inst{31-27} = 0;
  let Inst{26}    = 1;
  let Inst{25-23} = 0b000;
  let Inst{22-21} = 0b00;
  let Inst{20}    = 0;
  let Inst{19-17} = fcbit;
  let Inst{16}    = 0;
}

// FPU comparison instructions: FPCC[fcbit] = reg2 cmp reg1
// Used for: CMPF.S, CMPF.D
// Encoding: reg2[15:11], 111111[10:5], reg1[4:0] | 0fcond[31:27], 1000011[26:20], fcbit[19:17], dbl[16]
class FormatFPU_CMP<bit dbl, dag outs, dag ins, string asmstr, list<dag> pattern>
    : FormatFI<outs, ins, asmstr, pattern> {
  bits<5> reg1;
  bits<5> reg2;
  bits<4> fcond;
  bits<3> fcbit;

  let Inst{15-11} = reg2;
  let Inst{4-0}   = reg1;
  let Inst{31}    = 0;
  let Inst{30-27} = fcond;
  let Inst{26}    = 1;
  let Inst{25-23} = 0b000;
  let Inst{22-20} = 0b011;
  let Inst{19-17} = fcbit;
  let Inst{16}    = dbl;
}

