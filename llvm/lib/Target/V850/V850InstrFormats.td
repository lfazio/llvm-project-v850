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
  let Size = 2; // Default to 16-bit, 32-bit instructions override

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
              list<dag> pattern> : V850Inst16<outs, ins, asmstr, pattern> {
  bits<5> reg1;
  bits<5> reg2;

  let Inst{15 -11} = reg2;
  let Inst{10 -5} = opcode;
  let Inst{4 -0} = reg1;
}

//===----------------------------------------------------------------------===//
// Format II: Immediate-Register (16-bit)
// Bits: 15-11 = reg2, 10-5 = opcode, 4-0 = imm5
//===----------------------------------------------------------------------===//

class FormatII<bits<6> opcode, dag outs, dag ins, string asmstr,
               list<dag> pattern> : V850Inst16<outs, ins, asmstr, pattern> {
  bits<5> imm5;
  bits<5> reg2;

  let Inst{15 -11} = reg2;
  let Inst{10 -5} = opcode;
  let Inst{4 -0} = imm5;
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

  let Inst{15 -11} = 0; // reg2 = 0
  let Inst{10 -6} = opcode;
  let Inst{5 -0} = imm6;
}

//===----------------------------------------------------------------------===//
// Format III: Conditional Branch (16-bit)
// Bits: 15-11 = disp[8:4], 10-7 = opcode, 6-4 = disp[3:1], 3-0 = cond
//===----------------------------------------------------------------------===//

class FormatIII<bits<4> opcode, dag outs, dag ins, string asmstr,
                list<dag> pattern> : V850Inst16<outs, ins, asmstr, pattern> {
  bits<8> disp9; // Half-displacement (encoder shifts val >> 1)
  bits<4> cond;

  let Inst{15 -11} = disp9{7 -3};
  let Inst{10 -7} = opcode;
  let Inst{6 -4} = disp9{2 -0};
  let Inst{3 -0} = cond;
}

//===----------------------------------------------------------------------===//
// Format IV: Short Load/Store (16-bit)
// Bits: 15-11 = reg2, 10-7 = opcode, 6-0 = disp7 (or 6-1 = disp6, 0 = sub-op)
//===----------------------------------------------------------------------===//

class FormatIV<bits<4> opcode, dag outs, dag ins, string asmstr,
               list<dag> pattern> : V850Inst16<outs, ins, asmstr, pattern> {
  bits<5> reg2;
  bits<7> disp7;

  let Inst{15 -11} = reg2;
  let Inst{10 -7} = opcode;
  let Inst{6 -0} = disp7;
}

//===----------------------------------------------------------------------===//
// Format IV-E1: Short Load/Store (V850E1+, 16-bit)
// Bits: 15-11 = reg2, 10-4 = opcode (7 bits), 3-0 = disp4
// Used for: SLD.BU, SLD.HU (V850E1 and above)
// For halfword-aligned loads (SLD.HU), the instruction overrides disp4
// to encode disp5{4-1} (byte offset / 2).
//===----------------------------------------------------------------------===//

class FormatIV_E1<bits<7> opcode, dag outs, dag ins, string asmstr,
                  list<dag> pattern> : V850Inst16<outs, ins, asmstr, pattern> {
  bits<5> reg2;
  bits<4> disp4;

  let Inst{15 -11} = reg2;
  let Inst{10 -4} = opcode;
  let Inst{3 -0} = disp4;
}

//===----------------------------------------------------------------------===//
// Format V: Jump (32-bit)
// First halfword: 15-11 = reg2, 10-6 = opcode[5:1], 5-0 = disp22[5:0]
// Second halfword: 31-17 = disp22[21:7], 16 = disp22[6]
//===----------------------------------------------------------------------===//

class FormatV<bits<6> opcode, dag outs, dag ins, string asmstr,
              list<dag> pattern> : V850Inst32<outs, ins, asmstr, pattern> {
  bits<5> reg2;
  bits<22> disp22;

  let Inst{15 -11} = reg2;
  let Inst{10 -6} = opcode{5 -1};
  let Inst{5 -0} = disp22{5 -0};
  let Inst{31 -17} = disp22{21 -7};
  let Inst{16} = disp22{6};
}

//===----------------------------------------------------------------------===//
// Format VI: 3-operand (32-bit)
// First halfword: 15-11 = reg2, 10-5 = opcode, 4-0 = reg1
// Second halfword: 31-16 = imm16
//===----------------------------------------------------------------------===//

class FormatVI<bits<6> opcode, dag outs, dag ins, string asmstr,
               list<dag> pattern> : V850Inst32<outs, ins, asmstr, pattern> {
  bits<5> reg1;
  bits<5> reg2;
  bits<16> imm16;

  let Inst{15 -11} = reg2;
  let Inst{10 -5} = opcode;
  let Inst{4 -0} = reg1;
  let Inst{31 -16} = imm16;
}

//===----------------------------------------------------------------------===//
// Format VII: 32-bit Load/Store (32-bit)
// First halfword: 15-11 = reg2, 10-5 = opcode, 4-0 = reg1
// Second halfword: 31-17 = disp16[15:1], 16 = disp16[0] (or sub-op)
//===----------------------------------------------------------------------===//

class FormatVII<bits<6> opcode, dag outs, dag ins, string asmstr,
                list<dag> pattern> : V850Inst32<outs, ins, asmstr, pattern> {
  bits<5> reg1;
  bits<5> reg2;
  bits<16> disp16;

  let Inst{15 -11} = reg2;
  let Inst{10 -5} = opcode;
  let Inst{4 -0} = reg1;
  let Inst{31 -17} = disp16{15 -1};
  let Inst{16} = disp16{0};
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

  let Inst{15 -14} = subop;
  let Inst{13 -11} = bit3;
  let Inst{10 -5} = opcode;
  let Inst{4 -0} = reg1;
  let Inst{31 -16} = disp16;
}

//===----------------------------------------------------------------------===//
// Format IX: Extended 1 (32-bit)
// First halfword: 15-11 = reg2, 10-5 = 111111 (extended opcode), 4-0 = reg1
// Second halfword: 31-27 = RFU(0), 26-21 = sub-op, 20-16 = RFU(0)
//===----------------------------------------------------------------------===//

class FormatIX<bits<6> opcode, bits<6> subop, dag outs, dag ins, string asmstr,
               list<dag> pattern> : V850Inst32<outs, ins, asmstr, pattern> {
  bits<5> reg1;
  bits<5> reg2;

  let Inst{15 -11} = reg2;
  let Inst{10 -5} = opcode; // Extended opcode
  let Inst{4 -0} = reg1;
  let Inst{31 -27} = 0; // RFU
  let Inst{26 -21} = subop;
  let Inst{20 -16} = 0; // RFU
}

// Format IX with unified 10-bit sysreg operand (LDSR/STSR with bank selection)
// The sysreg operand encodes both regID and selID as a single 10-bit value:
//   Encoding = (selID << 5) | regID
// sysreg[4:0] = regID → instruction bits[4:0]
// sysreg[9:5] = selID → instruction bits[20:16]
// On base V850, selID=0 so bits[20:16]=0. On RH850G3M+, selID can be non-zero.
// The auto-generated decoder reconstructs the 10-bit value from both fields.
// Format IX for LDSR/STSR with unified 10-bit sysreg operand.
// sysreg encodes both regID (bits[4:0]) and selID (bits[9:5]):
//   Encoding = (selID << 5) | regID
// In the instruction: regID -> bits[4:0], selID -> bits[20:16].
// For base V850, selID=0 so bits[20:16]=0 (same as FormatIX RFU bits).
// Disassembly is handled by custom decode code in V850Disassembler.cpp
// that reconstructs the 10-bit sysreg encoding from bits[4:0] (regID)
// and bits[20:16] (selID).
class FormatIX_SysReg<bits<6> opcode, bits<6> subop, dag outs, dag ins,
                      string asmstr, list<dag> pattern>
    : V850Inst32<outs, ins, asmstr, pattern> {
  bits<10> sysreg; // Combined: selID[9:5] | regID[4:0]
  bits<5> reg2;

  let Inst{15 -11} = reg2;
  let Inst{10 -5} = opcode;        // Extended opcode
  let Inst{4 -0} = sysreg{4 -0};   // regID in instruction bits[4:0]
  let Inst{31 -27} = 0;            // RFU
  let Inst{26 -21} = subop;
  let Inst{20 -16} = sysreg{9 -5}; // selID in instruction bits[20:16]

  // Excluded from auto-generated decoder to avoid a conflict caused by the
  // variable selID field (bits[20:16]). Disassembly is handled by custom code
  // in V850Disassembler.cpp. Excluded from AsmMatcher; parsing is done
  // manually in V850AsmParser.cpp (matchAndEmitInstruction).
  let isCodeGenOnly = 1;
}

//===----------------------------------------------------------------------===//
// Format X: Extended 2 (32-bit)
// First halfword: 15-13 = RFU(0), 12-11 = sub-op[1:0], 10-5 = opcode, 4-0 =
// imm/vector Second halfword: 31-27 = RFU(0), 26-21 = sub-op, 20-16 = RFU(0)
//===----------------------------------------------------------------------===//

class FormatX<bits<6> opcode, bits<6> subop, dag outs, dag ins, string asmstr,
              list<dag> pattern> : V850Inst32<outs, ins, asmstr, pattern> {
  bits<5> vector;

  let Inst{15 -13} = 0; // RFU
  let Inst{12 -11} = subop{1 -0};
  let Inst{10 -5} = opcode;
  let Inst{4 -0} = vector;
  let Inst{31 -27} = 0; // RFU
  let Inst{26 -21} = subop;
  let Inst{20 -16} = 0; // RFU
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

  let Inst{15 -11} = reg2;
  let Inst{10 -5} = opcode; // Extended opcode
  let Inst{4 -0} = reg1;
  let Inst{31 -27} = reg3;
  let Inst{26 -21} = subop;
  let Inst{20 -16} = subid;
}

//===----------------------------------------------------------------------===//
// Format XI-MAC: Extended 4-operand reg-reg-reg-reg (32-bit)
// First halfword: 15-11 = reg2, 10-5 = 111111, 4-0 = reg1
// Second halfword: 31-27 = reg3, 26-21 = sub-op, 20-16 = reg4
// Used for: MAC, MACU (multiply-accumulate)
// Unlike FormatXI, bits[20:16] encode reg4 instead of a fixed subid.
//===----------------------------------------------------------------------===//

class FormatXI_MAC<bits<6> opcode, bits<6> subop, dag outs, dag ins,
                   string asmstr, list<dag> pattern>
    : V850Inst32<outs, ins, asmstr, pattern> {
  bits<5> reg1;
  bits<5> reg2;
  bits<5> reg3;
  bits<5> reg4;

  let Inst{15 -11} = reg2;
  let Inst{10 -5} = opcode;
  let Inst{4 -0} = reg1;
  let Inst{31 -27} = reg3;
  let Inst{26 -21} = subop;
  let Inst{20 -16} = reg4;
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

  let Inst{15 -11} = reg2;
  let Inst{10 -5} = opcode;    // Extended opcode
  let Inst{4 -0} = imm9{4 -0}; // imm9[4:0]
  let Inst{31 -27} = reg3;
  let Inst{26 -21} = subop;
  let Inst{20 -17} = imm9{8 -5}; // imm9[8:5]
  let Inst{16} = 0;
}

//===----------------------------------------------------------------------===//
// Format XII: Extended 3-operand imm-reg-reg (32-bit)
// First halfword: 15-11 = reg2, 10-5 = 111111, 4-0 = imm5
// Second halfword: 31-27 = reg3, 26-21 = sub-op, 20-17 = cond, 16 = 0
// Used for: CMOV with immediate
//===----------------------------------------------------------------------===//

class FormatXII<bits<6> opcode, bits<6> subop, dag outs, dag ins, string asmstr,
                list<dag> pattern> : V850Inst32<outs, ins, asmstr, pattern> {
  bits<5> imm5;
  bits<5> reg2;
  bits<5> reg3;
  bits<4> cond;

  let Inst{15 -11} = reg2;
  let Inst{10 -5} = opcode; // Extended opcode
  let Inst{4 -0} = imm5;
  let Inst{31 -27} = reg3;
  let Inst{26 -21} = subop;
  let Inst{20 -17} = cond;
  let Inst{16} = 0;
}

// Note: For conditional operations with extended opcode, use FormatXII with
// opcode=0b111111 instead of a separate class.

//===----------------------------------------------------------------------===//
// Format XIII: PREPARE/DISPOSE (32-bit)
// First halfword: 15-11 = 00000, 10-6 = 11001, 5-1 = imm5, 0 = list12[0]
// Second halfword: 31-21 = list12[11:1], 20-16 = reg1 (or 00000 for PREPARE)
// Used for: PREPARE, DISPOSE
//===----------------------------------------------------------------------===//

class FormatXIII<bits<5> opcode, dag outs, dag ins, string asmstr,
                 list<dag> pattern> : V850Inst32<outs, ins, asmstr, pattern> {
  bits<5> imm5;
  bits<12> list12;
  bits<5> reg1;

  let Inst{15 -11} = 0;     // Fixed
  let Inst{10 -6} = opcode; // PREPARE/DISPOSE opcode
  let Inst{5 -1} = imm5;
  let Inst{0} = list12{0};          // list12 bit 0 (r30)
  let Inst{31 -21} = list12{11 -1}; // list12 bits 11:1
  let Inst{20 -16} = reg1;
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

class FormatVI_E1<bits<6> opcode, dag outs, dag ins, string asmstr,
                  list<dag> pattern> : V850Inst48<outs, ins, asmstr, pattern> {
  bits<5> reg1;
  bits<32> imm32;

  let Inst{15 -11} = 0; // reg2 field (must be 0)
  let Inst{10 -5} = opcode;
  let Inst{4 -0} = reg1;
  let Inst{31 -16} = imm32{15 -0};  // imm32[15:0]
  let Inst{47 -32} = imm32{31 -16}; // imm32[31:16]
}

//===----------------------------------------------------------------------===//
// Format VI-E2: 48-bit Jump with 32-bit displacement (V850E2+)
// Used for: JARL disp32, JMP disp32, JR disp32
// First halfword:  15-11 = reg2 (unused, set to 0), 10-5 = opcode, 4-0 = reg1
// Second halfword: 31-17 = disp32[15:1], 16 = disp32[0]
// Third halfword:  47-32 = disp32[31:16]
//===----------------------------------------------------------------------===//

class FormatVI_E2<bits<6> opcode, dag outs, dag ins, string asmstr,
                  list<dag> pattern> : V850Inst48<outs, ins, asmstr, pattern> {
  bits<5> reg1;
  bits<32> disp32;

  let Inst{15 -11} = 0; // reg2 field (unused)
  let Inst{10 -5} = opcode;
  let Inst{4 -0} = reg1;
  let Inst{16} = disp32{0};          // disp32 bit 0
  let Inst{31 -17} = disp32{15 -1};  // disp32[15:1]
  let Inst{47 -32} = disp32{31 -16}; // disp32[31:16]
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
// - Arithmetic (ADDF/SUBF/MULF/DIVF): bits 26=1, 25-23=000, 22-21=11,
// 20-17=subop
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
  let Inst{10 -5} = 0b111111;
}

// FPU 3-operand instructions: reg3 = reg2 op reg1
// Used for: ADDF, SUBF, MULF, DIVF, MAXF, MINF
class FormatFPU_RRR<bits<4> subop, dag outs, dag ins, string asmstr,
                    list<dag> pattern> : FormatFI<outs, ins, asmstr, pattern> {
  bits<5> reg1;
  bits<5> reg2;
  bits<5> reg3;

  let Inst{15 -11} = reg2;
  let Inst{4 -0} = reg1;
  let Inst{31 -27} = reg3;
  let Inst{26} = 1;
  let Inst{25 -23} = 0b000; // Category
  let Inst{22 -21} = 0b11;  // Type (arithmetic)
  let Inst{20 -17} = subop;
  let Inst{16} = 0;
}

// FPU 2-operand instructions: reg3 = op(reg2)
// Used for: ABSF, NEGF, SQRTF, RECIPF, RSQRTF
class FormatFPU_RR<bits<4> subop, dag outs, dag ins, string asmstr,
                   list<dag> pattern> : FormatFI<outs, ins, asmstr, pattern> {
  bits<5> reg2;
  bits<5> reg3;

  let Inst{15 -11} = reg2;
  let Inst{4 -0} = 0; // reg1 unused
  let Inst{31 -27} = reg3;
  let Inst{26} = 1;
  let Inst{25 -23} = 0b000; // Category
  let Inst{22 -21} = 0b10;  // Type (2-operand)
  let Inst{20 -17} = subop;
  let Inst{16} = 0;
}

// FPU 4-operand instructions: reg4 = (reg2 * reg1) +/- reg3
// Used for: MADDF.S, MSUBF.S, NMADDF.S, NMSUBF.S
// reg4 is encoded across bits 26 and 20-17
class FormatFPU_RRRR<bits<2> subop, dag outs, dag ins, string asmstr,
                     list<dag> pattern> : FormatFI<outs, ins, asmstr, pattern> {
  bits<5> reg1;
  bits<5> reg2;
  bits<5> reg3;
  bits<5> reg4;

  let Inst{15 -11} = reg2;
  let Inst{4 -0} = reg1;
  let Inst{31 -27} = reg3;
  let Inst{26} = reg4{4};        // reg4 bit 4
  let Inst{25 -23} = 0b101;      // Category for MADD
  let Inst{22 -21} = subop;      // 00=MADDF, 01=MSUBF, 10=NMADDF, 11=NMSUBF
  let Inst{20 -17} = reg4{3 -0}; // reg4 bits 3-0
  let Inst{16} = 0;
}

// FPU conversion/rounding instructions: reg3 = convert(reg2)
// The category and type bits vary based on source/dest types
// subop2 encodes source type, subop encodes destination type
class FormatFPU_CVT<bits<5> subop2, bits<3> category, bits<2> type,
                    bits<4> subop, dag outs, dag ins, string asmstr,
                    list<dag> pattern> : FormatFI<outs, ins, asmstr, pattern> {
  bits<5> reg2;
  bits<5> reg3;

  let Inst{15 -11} = reg2;
  let Inst{4 -0} = subop2; // Additional sub-opcode
  let Inst{31 -27} = reg3;
  let Inst{26} = 1;
  let Inst{25 -23} = category;
  let Inst{22 -21} = type;
  let Inst{20 -17} = subop; // Sub-operation code
  let Inst{16} = 0;
}

// TRFSR - Transfer floating-point status to PSW.Z
// Encoding: 00000 111111 00000 | 00000 1 000 00 0fff 0
// Where fff = fcbit (3 bits) in bits 19-17, bit 20 = 0
class FormatFPU_TRFSR<dag outs, dag ins, string asmstr, list<dag> pattern>
    : FormatFI<outs, ins, asmstr, pattern> {
  bits<3> fcbit;

  let Inst{15 -11} = 0;
  let Inst{4 -0} = 0;
  let Inst{31 -27} = 0;
  let Inst{26} = 1;
  let Inst{25 -23} = 0b000;
  let Inst{22 -21} = 0b00;
  let Inst{20} = 0;
  let Inst{19 -17} = fcbit;
  let Inst{16} = 0;
}

//===----------------------------------------------------------------------===//
// Format XI-PostInc: Post-increment/decrement load/store (32-bit)
// RH850G4MH+
// First halfword:  15-11 = dir (direction/signedness), 10-5 = 111111,
//                  4-0 = reg1 (base register, updated in-place)
// Second halfword: 31-27 = reg3 (data register), 26-21 = 011011 (subop),
//                  20-16 = subid (data type/size)
//
// dir encoding:
//   00010 = post-increment (signed load / store)
//   00011 = post-increment (unsigned load)
//   00100 = post-decrement (signed load / store)
//   00101 = post-decrement (unsigned load)
//
// subid encoding:
//   10000 = byte load, 10010 = byte store
//   10100 = halfword load, 10110 = halfword store
//   11000 = word load, 11010 = word store
//===----------------------------------------------------------------------===//

class FormatXI_PostInc<bits<5> dir, bits<5> subid, dag outs, dag ins,
                       string asmstr, list<dag> pattern>
    : V850Inst32<outs, ins, asmstr, pattern> {
  bits<5> reg1;
  bits<5> reg3;

  let Inst{15 -11} = dir;       // Direction/signedness (NOT a register)
  let Inst{10 -5} = 0b111111;   // opcode (always)
  let Inst{4 -0} = reg1;        // Base address register
  let Inst{31 -27} = reg3;      // Data register
  let Inst{26 -21} = 0b011011;  // subop (always)
  let Inst{20 -16} = subid;     // Data type
}

//===----------------------------------------------------------------------===//
// Format XI-MPU: MPU bulk load/store (32-bit)
// First halfword: eh[15:11] 111111[10:5] reg1[4:0]
// Second halfword: et[31:27] 00101[26:22] subid[21:16]
//
// Used for: LDM.MP, STM.MP (RH850G4MH2)
//
// LDM.MP: rrrrr111111RRRRR wwwww00101100110
// STM.MP: rrrrr111111RRRRR wwwww00101100100
//
// rrrrr = eh (start entry), wwwww = et (end entry), RRRRR = reg1 (base addr)
//===----------------------------------------------------------------------===//

class FormatXI_MPU<bits<11> subop_subid, dag outs, dag ins,
                   string asmstr, list<dag> pattern>
    : V850Inst32<outs, ins, asmstr, pattern> {
  bits<5> reg1;
  bits<5> eh;
  bits<5> et;

  let Inst{15 -11} = eh;             // Start entry number
  let Inst{10 -5} = 0b111111;        // opcode (always)
  let Inst{4 -0} = reg1;             // Base address register
  let Inst{31 -27} = et;             // End entry number
  let Inst{26 -16} = subop_subid;    // subop + subid
}

//===----------------------------------------------------------------------===//
// Format X-HVTRAP: Hypervisor trap (32-bit)
// First halfword:  00000 111111 vector5[4:0]
// Second halfword: 00000 00100 0 10000
//
// Used for: HVTRAP (RH850G4MH2)
//===----------------------------------------------------------------------===//

class FormatX_HVTRAP<dag outs, dag ins, string asmstr, list<dag> pattern>
    : V850Inst32<outs, ins, asmstr, pattern> {
  bits<5> vector;

  let Inst{15 -11} = 0;
  let Inst{10 -5} = 0b111111;
  let Inst{4 -0} = vector;
  let Inst{31 -16} = 0b0000000100010000;
}

//===----------------------------------------------------------------------===//
// Format X-GSR: Guest system register bulk load/store (32-bit)
// First halfword:  00000 111111 reg1[4:0]
// Second halfword: disc[31:27] 001011 00000[20:16]
//
// disc = 10011 for LDM.GSR, 10010 for STM.GSR
//
// Used for: LDM.GSR, STM.GSR (RH850G4MH2)
//===----------------------------------------------------------------------===//

class FormatX_GSR<bits<5> disc, dag outs, dag ins, string asmstr,
                  list<dag> pattern>
    : V850Inst32<outs, ins, asmstr, pattern> {
  bits<5> reg1;

  let Inst{15 -11} = 0;
  let Inst{10 -5} = 0b111111;
  let Inst{4 -0} = reg1;
  let Inst{31 -27} = disc;
  let Inst{26 -21} = 0b001011;
  let Inst{20 -16} = 0;
}

// FPU comparison instructions: FPCC[fcbit] = reg2 cmp reg1
// Used for: CMPF.S, CMPF.D
// Encoding: reg2[15:11], 111111[10:5], reg1[4:0] | 0fcond[31:27],
// 1000011[26:20], fcbit[19:17], dbl[16]
class FormatFPU_CMP<bit dbl, dag outs, dag ins, string asmstr,
                    list<dag> pattern> : FormatFI<outs, ins, asmstr, pattern> {
  bits<5> reg1;
  bits<5> reg2;
  bits<4> fcond;
  bits<3> fcbit;

  let Inst{15 -11} = reg2;
  let Inst{4 -0} = reg1;
  let Inst{31} = 0;
  let Inst{30 -27} = fcond;
  let Inst{26} = 1;
  let Inst{25 -23} = 0b000;
  let Inst{22 -20} = 0b011;
  let Inst{19 -17} = fcbit;
  let Inst{16} = dbl;
}

//===----------------------------------------------------------------------===//
// Format M: FXU (Extended Floating-point Unit) Instruction Formats
// RH850G4MH+ only.  These use a separate opcode (111111 for 32-bit,
// 111101 for 48-bit) and operate on wreg0-wreg31 (128-bit vector registers).
//
// Bit layout overview (from ISA documentation):
//   32-bit (2OP/3OP):
//     bits[15:11] = wreg2
//     bits[10:5]  = opcode (111111)
//     bits[4:0]   = sub-opcode (2OP) or wreg1 (3OP)
//     bits[31:27] = wreg3
//     bits[26:16] = sub-opcode (11 bits)
//
//   48-bit (4OP / imm12 / D):
//     bits[15:11] = sub-opcode (5 bits)  [or reg2 for Format D]
//     bits[10:5]  = opcode (111101)
//     bits[4:0]   = wreg1                [or reg1 for Format D]
//     bits[31:27] = wreg3
//     bits[26:16] = sub-opcode (11 bits)
//     bits[47:43] = wreg2                [or disp16[15:11] for Format D]
//     bits[42:37] = sub-opcode (6 bits)  [or disp16[10:5] for Format D]
//     bits[36:32] = wreg4                [or disp16[4:0] for Format D]
//===----------------------------------------------------------------------===//

// Format M: 2OP (32-bit)
// wreg3 = op(wreg2)
// Used for: ABSF.S4, NEGF.S4, SQRTF.S4, RECIPF.S4, RSQRTF.S4, MOVV.W4,
//           TRFSRV.W4, FLPV.S4, and all 14 conversion/rounding instructions.
//
// subop5[4:0] differentiates instructions when subop11 is shared (0x5a0).
// For FLPV.S4: subop5 = 0b110xx (bits[1:0] = imm2).
// For TRFSRV.W4: subop5 = 0b11111, wreg2 encodes imm3 in bits[2:0].
class FormatM_2OP<bits<5> subop5, bits<11> subop11,
                  dag outs, dag ins, string asmstr, list<dag> pattern>
    : V850Inst32<outs, ins, asmstr, pattern> {
  bits<5> wreg2;
  bits<5> wreg3;

  let Inst{15 -11} = wreg2;
  let Inst{10 -5}  = 0b111111;  // opcode
  let Inst{4  -0}  = subop5;
  let Inst{31 -27} = wreg3;
  let Inst{26 -16} = subop11;
}

// Format M: 3OP (32-bit)
// wreg3 = op(wreg2, wreg1)
// Used for: ADDF.S4, SUBF.S4, MULF.S4, DIVF.S4, MAXF.S4, MINF.S4,
//           FMAF.S4, FMSF.S4, FNMAF.S4, FNMSF.S4, reduction ops,
//           compound ops, exchange ops, CMPF.S4.
//
// subop11 differentiates all 3OP instructions.
// For CMPF.S4: subop11 = 0b101100xxxx0 (4-bit fcond occupies bits[20:17]).
class FormatM_3OP<bits<11> subop11,
                  dag outs, dag ins, string asmstr, list<dag> pattern>
    : V850Inst32<outs, ins, asmstr, pattern> {
  bits<5> wreg1;
  bits<5> wreg2;
  bits<5> wreg3;

  let Inst{15 -11} = wreg2;
  let Inst{10 -5}  = 0b111111;  // opcode
  let Inst{4  -0}  = wreg1;
  let Inst{31 -27} = wreg3;
  let Inst{26 -16} = subop11;
}

// Format M: 4OP (48-bit)
// wreg4 = op(wreg3, wreg2, wreg1)
// Used for: FMAF.S4, FMSF.S4, FNMAF.S4, FNMSF.S4, CMOVF.W4.
//
// First 32-bit word:
//   bits[15:11] = subop5a (5-bit sub-opcode)
//   bits[10:5]  = opcode (111101)
//   bits[4:0]   = wreg1
//   bits[31:27] = wreg3
//   bits[26:16] = subop11
//
// Second 16-bit word (bits[47:32]):
//   bits[47:43] = wreg2
//   bits[42:37] = subop6  (6-bit sub-opcode)
//   bits[36:32] = wreg4
class FormatM_4OP<bits<5> subop5a, bits<11> subop11, bits<6> subop6,
                  dag outs, dag ins, string asmstr, list<dag> pattern>
    : V850Inst48<outs, ins, asmstr, pattern> {
  bits<5> wreg1;
  bits<5> wreg2;
  bits<5> wreg3;
  bits<5> wreg4;

  let Inst{15 -11} = subop5a;
  let Inst{10 -5}  = 0b111101;  // opcode (48-bit)
  let Inst{4  -0}  = wreg1;
  let Inst{31 -27} = wreg3;
  let Inst{26 -16} = subop11;
  let Inst{47 -43} = wreg2;
  let Inst{42 -37} = subop6;
  let Inst{36 -32} = wreg4;
}

// Format M: imm12 (48-bit)
// wreg3 = op(wreg2, wreg1, imm12)  [or op(wreg2, imm12, wreg3)]
// Used for: SHFLV.W4.
//
// The highest bit of the immediate (bit 12) is encoded in the sub-opcode.
// The remaining 11 bits occupy bits[42:32].
//
// First 32-bit word:
//   bits[15:11] = subop5a (5-bit sub-opcode; for SHFLV: contains imm12[11])
//   bits[10:5]  = opcode (111101)
//   bits[4:0]   = wreg1
//   bits[31:27] = wreg3
//   bits[26:16] = subop11 (11-bit sub-opcode; for SHFLV: bits[26:22] fixed,
//                          bit[21] = imm12[11] MSB)
//
// Second 16-bit word (bits[47:32]):
//   bits[47:43] = wreg2
//   bits[42:32] = imm12[10:0] (lower 11 bits of immediate)
class FormatM_Imm12<bits<5> subop5a, bits<11> subop11,
                    dag outs, dag ins, string asmstr, list<dag> pattern>
    : V850Inst48<outs, ins, asmstr, pattern> {
  bits<5>  wreg1;
  bits<5>  wreg2;
  bits<5>  wreg3;
  bits<12> imm12;

  let Inst{15 -11} = subop5a;
  let Inst{10 -5}  = 0b111101;    // opcode (48-bit)
  let Inst{4  -0}  = wreg1;
  let Inst{31 -27} = wreg3;
  let Inst{26 -16} = subop11;
  let Inst{47 -43} = wreg2;
  let Inst{42 -32} = imm12{10 -0}; // lower 11 bits
}

// Format M: D (48-bit, memory load/store)
// wreg3 = op(disp16[reg1])  or  op(wreg3, disp16[reg1])
// Used for: LDV.W, LDV.DW, LDV.QW, LDVZ.H4, STV.W, STV.DW, STV.QW, STVZ.H4.
//
// First 32-bit word:
//   bits[15:11] = reg2 (GPR, base address register for stores; 00000 for loads)
//   bits[10:5]  = opcode (111101)
//   bits[4:0]   = reg1 (GPR, base address register)
//   bits[31:27] = wreg3 (vector register)
//   bits[26:16] = subop11 (11-bit sub-opcode)
//
// Second 16-bit word (bits[47:32]):
//   bits[47:32] = disp16 (16-bit signed displacement)
//
// Note: For LDV.W, the imm4 field encoding bits[25:22] in subop11 selects
// which of the 4 elements to load into.
class FormatM_D<bits<11> subop11,
                dag outs, dag ins, string asmstr, list<dag> pattern>
    : V850Inst48<outs, ins, asmstr, pattern> {
  bits<5>  reg1;
  bits<5>  reg2;
  bits<5>  wreg3;
  bits<16> disp16;

  let Inst{15 -11} = reg2;
  let Inst{10 -5}  = 0b111101;  // opcode (48-bit)
  let Inst{4  -0}  = reg1;
  let Inst{31 -27} = wreg3;
  let Inst{26 -16} = subop11;
  let Inst{47 -32} = disp16;
}
