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
  bits<9> disp9;  // PC-relative displacement (bit 0 implicitly 0)
  bits<4> cond;

  let Inst{15-11} = disp9{8-4};
  let Inst{10-7}  = opcode;
  let Inst{6-4}   = disp9{3-1};
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

