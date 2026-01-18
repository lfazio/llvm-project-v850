//===-- V850AsmParser.cpp - Parse V850 assembly to MCInst instructions ----===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/V850MCTargetDesc.h"
#include "TargetInfo/V850TargetInfo.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/StringSwitch.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCParser/AsmLexer.h"
#include "llvm/MC/MCParser/MCAsmParser.h"
#include "llvm/MC/MCParser/MCParsedAsmOperand.h"
#include "llvm/MC/MCParser/MCTargetAsmParser.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/Compiler.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/MathExtras.h"
#include "llvm/Support/SMLoc.h"
#include "llvm/Support/raw_ostream.h"
#include <cstdint>
#include <memory>

using namespace llvm;

#define DEBUG_TYPE "v850-asm-parser"

namespace {

class V850Operand;

class V850AsmParser : public MCTargetAsmParser {
  MCAsmParser &Parser;
  const MCRegisterInfo &MRI;
  const MCSubtargetInfo &STI;

  bool parseRegister(MCRegister &Reg, SMLoc &StartLoc, SMLoc &EndLoc) override;
  ParseStatus tryParseRegister(MCRegister &Reg, SMLoc &StartLoc,
                               SMLoc &EndLoc) override;

  bool parseInstruction(ParseInstructionInfo &Info, StringRef Name,
                        SMLoc NameLoc, OperandVector &Operands) override;

  bool matchAndEmitInstruction(SMLoc IDLoc, unsigned &Opcode,
                               OperandVector &Operands, MCStreamer &Out,
                               uint64_t &ErrorInfo,
                               bool MatchingInlineAsm) override;

  ParseStatus parseOperand(OperandVector &Operands, StringRef Mnemonic);
  ParseStatus parseMemoryOperand(OperandVector &Operands);
  ParseStatus parseImmediate(OperandVector &Operands);
  ParseStatus parseBranchTarget(OperandVector &Operands);
  ParseStatus parseCondCode(OperandVector &Operands);
  ParseStatus parseFPCondCode(OperandVector &Operands);

  MCRegister matchRegisterName(StringRef Name);
  MCRegister matchRegisterAltName(StringRef Name);

  bool parseOperandWithModifier(OperandVector &Operands);

// Auto-generated instruction matching functions
#define GET_ASSEMBLER_HEADER
#include "V850GenAsmMatcher.inc"

  ParseStatus parseDirective(AsmToken DirectiveID) override;

  /// Validate register pair constraints for double-precision FPU instructions.
  /// Returns true if validation fails (odd register used where even required).
  bool validateFPURegisterPair(StringRef Mnemonic, const OperandVector &Operands,
                               SMLoc IDLoc);

public:
  V850AsmParser(const MCSubtargetInfo &STI, MCAsmParser &Parser,
                const MCInstrInfo &MII, const MCTargetOptions &Options)
      : MCTargetAsmParser(Options, STI, MII), Parser(Parser),
        MRI(*Parser.getContext().getRegisterInfo()), STI(STI) {
    setAvailableFeatures(ComputeAvailableFeatures(STI.getFeatureBits()));
  }
};

/// V850Operand - Instances of this class represent a parsed V850 machine
/// instruction operand.
class V850Operand : public MCParsedAsmOperand {
public:
  enum KindTy {
    K_Token,
    K_Register,
    K_Immediate,
    K_Memory
  } Kind;

private:
  struct TokOp {
    const char *Data;
    unsigned Length;
  };

  struct RegOp {
    MCRegister RegNum;
  };

  struct ImmOp {
    const MCExpr *Val;
  };

  struct MemOp {
    MCRegister BaseReg;
    const MCExpr *Disp;
  };

  SMLoc StartLoc, EndLoc;

  union {
    TokOp Tok;
    RegOp Reg;
    ImmOp Imm;
    MemOp Mem;
  };

public:
  V850Operand(KindTy K) : Kind(K) {}

  bool isToken() const override { return Kind == K_Token; }
  bool isReg() const override { return Kind == K_Register; }
  bool isImm() const override { return Kind == K_Immediate; }
  bool isMem() const override { return Kind == K_Memory; }

  // Used by TableGen matchers
  bool isGPR() const { return isReg(); }
  bool isSysReg() const { return isReg(); }

  bool isSimm5() const {
    if (!isImm())
      return false;
    if (const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(getImm()))
      return isInt<5>(CE->getValue());
    return true;
  }

  bool isUimm5() const {
    if (!isImm())
      return false;
    if (const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(getImm()))
      return isUInt<5>(CE->getValue());
    return true;
  }

  bool isSimm16() const {
    if (!isImm())
      return false;
    if (const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(getImm()))
      return isInt<16>(CE->getValue());
    return true;
  }

  bool isUimm16() const {
    if (!isImm())
      return false;
    if (const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(getImm()))
      return isUInt<16>(CE->getValue());
    return true;
  }

  bool isUimm3() const {
    if (!isImm())
      return false;
    if (const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(getImm()))
      return isUInt<3>(CE->getValue());
    return true;
  }

  bool isUimm7() const {
    if (!isImm())
      return false;
    if (const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(getImm()))
      return isUInt<7>(CE->getValue());
    return true;
  }

  // For short load/store with implicit EP base
  bool isImm7EP() const { return isUimm7(); }

  // For SLD.BU 4-bit displacement
  bool isImm4() const {
    if (!isImm())
      return false;
    if (const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(getImm()))
      return isUInt<4>(CE->getValue());
    return true;
  }

  // For SLD.HU 5-bit displacement
  bool isImm5() const {
    if (!isImm())
      return false;
    if (const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(getImm()))
      return isUInt<5>(CE->getValue());
    return true;
  }

  bool isBrtarget9() const { return isImm(); }
  bool isBrtarget22() const { return isImm(); }
  bool isBrtarget32() const { return isImm(); }
  bool isCondcode() const { return isImm(); }
  bool isCmov_cond() const { return isImm(); }
  bool isUimm6() const {
    if (!isImm())
      return false;
    if (const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(getImm()))
      return isUInt<6>(CE->getValue());
    return true;
  }

  // Memory operand predicates for different addressing modes
  bool isMemDisp16() const { return isMem(); }

  SMLoc getStartLoc() const override { return StartLoc; }
  SMLoc getEndLoc() const override { return EndLoc; }

  MCRegister getReg() const override {
    assert(isReg() && "Invalid type access!");
    return Reg.RegNum;
  }

  const MCExpr *getImm() const {
    assert(isImm() && "Invalid type access!");
    return Imm.Val;
  }

  StringRef getToken() const {
    assert(isToken() && "Invalid type access!");
    return StringRef(Tok.Data, Tok.Length);
  }

  MCRegister getMemBaseReg() const {
    assert(isMem() && "Invalid type access!");
    return Mem.BaseReg;
  }

  const MCExpr *getMemDisp() const {
    assert(isMem() && "Invalid type access!");
    return Mem.Disp;
  }

  void print(raw_ostream &OS, const MCAsmInfo &MAI) const override {
    switch (Kind) {
    case K_Token:
      OS << "Token: " << getToken();
      break;
    case K_Register:
      OS << "Reg: " << getReg();
      break;
    case K_Immediate:
      OS << "Imm: ";
      MAI.printExpr(OS, *getImm());
      break;
    case K_Memory:
      OS << "Mem: " << getMemBaseReg() << " + ";
      MAI.printExpr(OS, *getMemDisp());
      break;
    }
  }

  static std::unique_ptr<V850Operand> createToken(StringRef Str, SMLoc S) {
    auto Op = std::make_unique<V850Operand>(K_Token);
    Op->Tok.Data = Str.data();
    Op->Tok.Length = Str.size();
    Op->StartLoc = S;
    Op->EndLoc = S;
    return Op;
  }

  static std::unique_ptr<V850Operand> createReg(MCRegister Reg, SMLoc S,
                                                 SMLoc E) {
    auto Op = std::make_unique<V850Operand>(K_Register);
    Op->Reg.RegNum = Reg;
    Op->StartLoc = S;
    Op->EndLoc = E;
    return Op;
  }

  static std::unique_ptr<V850Operand> createImm(const MCExpr *Val, SMLoc S,
                                                 SMLoc E) {
    auto Op = std::make_unique<V850Operand>(K_Immediate);
    Op->Imm.Val = Val;
    Op->StartLoc = S;
    Op->EndLoc = E;
    return Op;
  }

  static std::unique_ptr<V850Operand> createMem(MCRegister Base,
                                                 const MCExpr *Disp, SMLoc S,
                                                 SMLoc E) {
    auto Op = std::make_unique<V850Operand>(K_Memory);
    Op->Mem.BaseReg = Base;
    Op->Mem.Disp = Disp;
    Op->StartLoc = S;
    Op->EndLoc = E;
    return Op;
  }

  // Used by TableGen matchers
  void addRegOperands(MCInst &Inst, unsigned N) const {
    assert(N == 1 && "Invalid number of operands!");
    Inst.addOperand(MCOperand::createReg(getReg()));
  }

  void addImmOperands(MCInst &Inst, unsigned N) const {
    assert(N == 1 && "Invalid number of operands!");
    if (const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(getImm()))
      Inst.addOperand(MCOperand::createImm(CE->getValue()));
    else
      Inst.addOperand(MCOperand::createExpr(getImm()));
  }

  void addSimm5Operands(MCInst &Inst, unsigned N) const {
    addImmOperands(Inst, N);
  }

  void addUimm5Operands(MCInst &Inst, unsigned N) const {
    addImmOperands(Inst, N);
  }

  void addSimm16Operands(MCInst &Inst, unsigned N) const {
    addImmOperands(Inst, N);
  }

  void addUimm16Operands(MCInst &Inst, unsigned N) const {
    addImmOperands(Inst, N);
  }

  void addUimm3Operands(MCInst &Inst, unsigned N) const {
    addImmOperands(Inst, N);
  }

  void addBrtarget9Operands(MCInst &Inst, unsigned N) const {
    addImmOperands(Inst, N);
  }

  void addBrtarget22Operands(MCInst &Inst, unsigned N) const {
    addImmOperands(Inst, N);
  }

  void addBrtarget32Operands(MCInst &Inst, unsigned N) const {
    addImmOperands(Inst, N);
  }

  void addCondcodeOperands(MCInst &Inst, unsigned N) const {
    addImmOperands(Inst, N);
  }

  void addCmov_condOperands(MCInst &Inst, unsigned N) const {
    addImmOperands(Inst, N);
  }

  void addUimm6Operands(MCInst &Inst, unsigned N) const {
    addImmOperands(Inst, N);
  }

  // Add memory operand as two separate operands: base register and displacement
  // This is used by Format VIII instructions (SET1, NOT1, CLR1, TST1)
  // The instruction encoding expects (bit3, reg1, disp16) but assembly is
  // "set1 bit, disp[reg]"
  void addMemDisp16Operands(MCInst &Inst, unsigned N) const {
    assert(N == 2 && "Invalid number of operands for MemDisp16!");
    assert(isMem() && "Expected memory operand!");
    // Add base register first (reg1 in encoding)
    Inst.addOperand(MCOperand::createReg(getMemBaseReg()));
    // Add displacement second (disp16 in encoding)
    if (const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(getMemDisp()))
      Inst.addOperand(MCOperand::createImm(CE->getValue()));
    else
      Inst.addOperand(MCOperand::createExpr(getMemDisp()));
  }
};

} // end anonymous namespace

#define GET_REGISTER_MATCHER
#define GET_MATCHER_IMPLEMENTATION
#define GET_SUBTARGET_FEATURE_NAME
#include "V850GenAsmMatcher.inc"

MCRegister V850AsmParser::matchRegisterName(StringRef Name) {
  MCRegister Reg = MatchRegisterName(Name);
  if (Reg)
    return Reg;
  return MatchRegisterAltName(Name);
}

MCRegister V850AsmParser::matchRegisterAltName(StringRef Name) {
  // Handle alternate register names
  return StringSwitch<MCRegister>(Name.lower())
      .Case("zero", V850::R0)
      .Case("sp", V850::SP)
      .Case("gp", V850::GP)
      .Case("tp", V850::TP)
      .Case("ep", V850::EP)
      .Case("lp", V850::LP)
      .Default(MCRegister());
}

bool V850AsmParser::parseRegister(MCRegister &Reg, SMLoc &StartLoc,
                                   SMLoc &EndLoc) {
  return !tryParseRegister(Reg, StartLoc, EndLoc).isSuccess();
}

ParseStatus V850AsmParser::tryParseRegister(MCRegister &Reg, SMLoc &StartLoc,
                                             SMLoc &EndLoc) {
  const AsmToken &Tok = Parser.getTok();
  StartLoc = Tok.getLoc();
  EndLoc = Tok.getEndLoc();

  if (Tok.isNot(AsmToken::Identifier))
    return ParseStatus::NoMatch;

  StringRef Name = Tok.getString();
  Reg = matchRegisterName(Name);
  if (!Reg)
    Reg = matchRegisterAltName(Name);

  if (!Reg)
    return ParseStatus::NoMatch;

  Parser.Lex(); // Consume register name
  return ParseStatus::Success;
}

ParseStatus V850AsmParser::parseOperand(OperandVector &Operands,
                                        StringRef Mnemonic) {
  // Try to parse as register first
  MCRegister Reg;
  SMLoc StartLoc, EndLoc;
  if (tryParseRegister(Reg, StartLoc, EndLoc).isSuccess()) {
    Operands.push_back(V850Operand::createReg(Reg, StartLoc, EndLoc));
    return ParseStatus::Success;
  }

  // Check for memory operand starting with '[' (e.g., jmp [reg])
  if (getLexer().is(AsmToken::LBrac))
    return parseMemoryOperand(Operands);

  // For FPU comparison instructions, try FP condition codes first
  // These have priority over regular condition codes for cmpf.s/cmpf.d
  if (Mnemonic.starts_with("cmpf.")) {
    if (parseFPCondCode(Operands).isSuccess())
      return ParseStatus::Success;
  }

  // Try to parse as a condition code (for cmov, setf, sasf, adf, sbf, etc.)
  if (parseCondCode(Operands).isSuccess())
    return ParseStatus::Success;

  // Try to parse as an immediate expression
  if (parseImmediate(Operands).isSuccess()) {
    // Check for memory base register: disp[reg]
    if (getLexer().is(AsmToken::LBrac))
      return parseMemoryOperand(Operands);
    return ParseStatus::Success;
  }

  Error(Parser.getTok().getLoc(), "expected register or immediate");
  return ParseStatus::NoMatch;
}

ParseStatus V850AsmParser::parseImmediate(OperandVector &Operands) {
  SMLoc StartLoc = Parser.getTok().getLoc();
  const MCExpr *Expr;

  if (Parser.parseExpression(Expr))
    return ParseStatus::Failure;

  SMLoc EndLoc = Parser.getTok().getLoc();
  Operands.push_back(V850Operand::createImm(Expr, StartLoc, EndLoc));
  return ParseStatus::Success;
}

ParseStatus V850AsmParser::parseMemoryOperand(OperandVector &Operands) {
  // Parse [reg] - adds '[', register, ']' as separate operands
  if (Parser.getTok().isNot(AsmToken::LBrac))
    return ParseStatus::NoMatch;

  Operands.push_back(V850Operand::createToken("[", Parser.getTok().getLoc()));
  Parser.Lex(); // Consume '['

  MCRegister BaseReg;
  SMLoc RegStart, RegEnd;
  if (!tryParseRegister(BaseReg, RegStart, RegEnd).isSuccess()) {
    Error(Parser.getTok().getLoc(), "expected register");
    return ParseStatus::Failure;
  }
  Operands.push_back(V850Operand::createReg(BaseReg, RegStart, RegEnd));

  if (Parser.getTok().isNot(AsmToken::RBrac)) {
    Error(Parser.getTok().getLoc(), "expected ']'");
    return ParseStatus::Failure;
  }
  Operands.push_back(V850Operand::createToken("]", Parser.getTok().getLoc()));
  Parser.Lex(); // Consume ']'

  return ParseStatus::Success;
}

ParseStatus V850AsmParser::parseBranchTarget(OperandVector &Operands) {
  return parseImmediate(Operands);
}

ParseStatus V850AsmParser::parseCondCode(OperandVector &Operands) {
  SMLoc StartLoc = Parser.getTok().getLoc();

  if (Parser.getTok().isNot(AsmToken::Identifier))
    return ParseStatus::NoMatch;

  StringRef Name = Parser.getTok().getString();

  // Map condition code names to their numeric values
  // V850 condition codes (4-bit encoding)
  int CondVal = StringSwitch<int>(Name.lower())
      .Case("v", 0)      // Overflow
      .Case("c", 1)      // Carry / Lower
      .Case("l", 1)      // Lower (alias for c)
      .Case("z", 2)      // Zero / Equal
      .Case("e", 2)      // Equal (alias for z)
      .Case("nh", 3)     // Not higher
      .Case("n", 4)      // Negative
      .Case("t", 5)      // Always true (unconditional)
      .Case("lt", 6)     // Less than (signed)
      .Case("le", 7)     // Less or equal (signed)
      .Case("nv", 8)     // No overflow
      .Case("nc", 9)     // No carry / Not lower
      .Case("nl", 9)     // Not lower (alias for nc)
      .Case("nz", 10)    // Not zero / Not equal
      .Case("ne", 10)    // Not equal (alias for nz)
      .Case("h", 11)     // Higher
      .Case("p", 12)     // Positive
      .Case("sa", 13)    // Saturated
      .Case("ge", 14)    // Greater or equal (signed)
      .Case("gt", 15)    // Greater than (signed)
      .Case("f", 5)      // Always false mapped to always true (same encoding)
      .Default(-1);

  if (CondVal < 0)
    return ParseStatus::NoMatch;

  SMLoc EndLoc = Parser.getTok().getEndLoc();
  Parser.Lex(); // Consume the condition code token

  const MCExpr *Expr = MCConstantExpr::create(CondVal, getContext());
  Operands.push_back(V850Operand::createImm(Expr, StartLoc, EndLoc));
  return ParseStatus::Success;
}

ParseStatus V850AsmParser::parseFPCondCode(OperandVector &Operands) {
  SMLoc StartLoc = Parser.getTok().getLoc();

  if (Parser.getTok().isNot(AsmToken::Identifier))
    return ParseStatus::NoMatch;

  StringRef Name = Parser.getTok().getString();

  // Map FPU condition code names to their numeric values (4-bit encoding)
  // These are used by CMPF.S and CMPF.D instructions
  int FCondVal = StringSwitch<int>(Name.lower())
      .Case("f", 0)       // False
      .Case("un", 1)      // Unordered
      .Case("eq", 2)      // Equal
      .Case("ueq", 3)     // Unordered or Equal
      .Case("olt", 4)     // Ordered Less Than
      .Case("ult", 5)     // Unordered or Less Than
      .Case("ole", 6)     // Ordered Less or Equal
      .Case("ule", 7)     // Unordered or Less or Equal
      .Case("sf", 8)      // Signaling False
      .Case("ngle", 9)    // Not Greater, Less, or Equal
      .Case("seq", 10)    // Signaling Equal
      .Case("ngl", 11)    // Not Greater or Less
      .Case("lt", 12)     // Less Than
      .Case("nge", 13)    // Not Greater or Equal
      .Case("le", 14)     // Less or Equal
      .Case("ngt", 15)    // Not Greater Than
      .Default(-1);

  if (FCondVal < 0)
    return ParseStatus::NoMatch;

  SMLoc EndLoc = Parser.getTok().getEndLoc();
  Parser.Lex(); // Consume the FP condition code token

  const MCExpr *Expr = MCConstantExpr::create(FCondVal, getContext());
  Operands.push_back(V850Operand::createImm(Expr, StartLoc, EndLoc));
  return ParseStatus::Success;
}

bool V850AsmParser::parseInstruction(ParseInstructionInfo &Info, StringRef Name,
                                      SMLoc NameLoc, OperandVector &Operands) {
  // Add the mnemonic as first operand
  Operands.push_back(V850Operand::createToken(Name, NameLoc));

  // If there are no operands, we're done
  if (Parser.getTok().is(AsmToken::EndOfStatement))
    return false;

  // Parse first operand
  if (!parseOperand(Operands, Name).isSuccess())
    return true;

  // Parse subsequent operands
  while (Parser.getTok().is(AsmToken::Comma)) {
    Parser.Lex(); // Consume comma

    if (!parseOperand(Operands, Name).isSuccess())
      return true;
  }

  if (Parser.getTok().isNot(AsmToken::EndOfStatement)) {
    Error(Parser.getTok().getLoc(), "unexpected token in operand list");
    return true;
  }

  return false;
}

bool V850AsmParser::validateFPURegisterPair(StringRef Mnemonic,
                                             const OperandVector &Operands,
                                             SMLoc IDLoc) {
  // Double-precision FPU instructions require even-numbered registers for
  // register pairs. Validate the appropriate operands based on instruction.

  // Helper to check if a register operand is even-numbered
  auto isEvenRegister = [&](const MCParsedAsmOperand &Op) -> bool {
    const V850Operand &VOp = static_cast<const V850Operand &>(Op);
    if (!VOp.isReg())
      return true; // Not a register, skip validation
    MCRegister Reg = VOp.getReg();
    unsigned RegNo = MRI.getEncodingValue(Reg);
    return (RegNo & 1) == 0;
  };

  // Get error location from operand if possible
  auto getOperandLoc = [&](unsigned Idx) -> SMLoc {
    if (Idx < Operands.size()) {
      const V850Operand &VOp = static_cast<const V850Operand &>(*Operands[Idx]);
      return VOp.getStartLoc();
    }
    return IDLoc;
  };

  // Double-precision arithmetic: addf.d, subf.d, mulf.d, divf.d, maxf.d, minf.d
  // Format: op reg1, reg2, reg3 - all three registers must be even
  if (Mnemonic == "addf.d" || Mnemonic == "subf.d" || Mnemonic == "mulf.d" ||
      Mnemonic == "divf.d" || Mnemonic == "maxf.d" || Mnemonic == "minf.d") {
    // Operands: [mnemonic, reg1, reg2, reg3]
    for (unsigned i = 1; i <= 3 && i < Operands.size(); ++i) {
      if (!isEvenRegister(*Operands[i])) {
        Error(getOperandLoc(i),
              "double-precision FPU instruction requires even-numbered register");
        return true;
      }
    }
    return false;
  }

  // Double-precision unary: absf.d, negf.d, sqrtf.d, recipf.d, rsqrtf.d
  // Format: op reg1, reg2 - both registers must be even
  if (Mnemonic == "absf.d" || Mnemonic == "negf.d" || Mnemonic == "sqrtf.d" ||
      Mnemonic == "recipf.d" || Mnemonic == "rsqrtf.d") {
    for (unsigned i = 1; i <= 2 && i < Operands.size(); ++i) {
      if (!isEvenRegister(*Operands[i])) {
        Error(getOperandLoc(i),
              "double-precision FPU instruction requires even-numbered register");
        return true;
      }
    }
    return false;
  }

  // Double-precision comparison: cmpf.d fcond, reg1, reg2, fcbit
  // reg1 and reg2 must be even (operands 2 and 3)
  if (Mnemonic == "cmpf.d") {
    for (unsigned i = 2; i <= 3 && i < Operands.size(); ++i) {
      if (!isEvenRegister(*Operands[i])) {
        Error(getOperandLoc(i),
              "double-precision FPU instruction requires even-numbered register");
        return true;
      }
    }
    return false;
  }

  // Conversion from double: cvtf.ds, cvtf.dw, cvtf.dl, cvtf.duw, cvtf.dul
  // Format: op reg1, reg2 - reg1 (source double) must be even
  if (Mnemonic == "cvtf.ds" || Mnemonic == "cvtf.dw" || Mnemonic == "cvtf.dl" ||
      Mnemonic == "cvtf.duw" || Mnemonic == "cvtf.dul") {
    if (Operands.size() > 1 && !isEvenRegister(*Operands[1])) {
      Error(getOperandLoc(1),
            "double-precision source register must be even-numbered");
      return true;
    }
    return false;
  }

  // Conversion to double: cvtf.sd, cvtf.wd, cvtf.ld, cvtf.uwd, cvtf.uld
  // Format: op reg1, reg2 - reg2 (dest double) must be even
  if (Mnemonic == "cvtf.sd" || Mnemonic == "cvtf.wd" || Mnemonic == "cvtf.ld" ||
      Mnemonic == "cvtf.uwd" || Mnemonic == "cvtf.uld") {
    if (Operands.size() > 2 && !isEvenRegister(*Operands[2])) {
      Error(getOperandLoc(2),
            "double-precision destination register must be even-numbered");
      return true;
    }
    return false;
  }

  // Rounding from double: trncf.d*, ceilf.d*, floorf.d*, cvtf.d* (to integer)
  // Format: op reg1, reg2 - reg1 (source double) must be even
  if (Mnemonic.starts_with("trncf.d") || Mnemonic.starts_with("ceilf.d") ||
      Mnemonic.starts_with("floorf.d")) {
    if (Operands.size() > 1 && !isEvenRegister(*Operands[1])) {
      Error(getOperandLoc(1),
            "double-precision source register must be even-numbered");
      return true;
    }
    // For long output (64-bit), dest must also be even
    if (Mnemonic.ends_with("l") || Mnemonic.ends_with("ul")) {
      if (Operands.size() > 2 && !isEvenRegister(*Operands[2])) {
        Error(getOperandLoc(2),
              "64-bit destination register must be even-numbered");
        return true;
      }
    }
    return false;
  }

  // Rounding from single to long: trncf.sl, trncf.sul, ceilf.sl, etc.
  // Format: op reg1, reg2 - reg2 (dest long) must be even
  if ((Mnemonic.starts_with("trncf.s") || Mnemonic.starts_with("ceilf.s") ||
       Mnemonic.starts_with("floorf.s")) &&
      (Mnemonic.ends_with("l") || Mnemonic.ends_with("ul"))) {
    if (Operands.size() > 2 && !isEvenRegister(*Operands[2])) {
      Error(getOperandLoc(2),
            "64-bit destination register must be even-numbered");
      return true;
    }
    return false;
  }

  return false;
}

bool V850AsmParser::matchAndEmitInstruction(SMLoc IDLoc, unsigned &Opcode,
                                             OperandVector &Operands,
                                             MCStreamer &Out,
                                             uint64_t &ErrorInfo,
                                             bool MatchingInlineAsm) {
  MCInst Inst;
  FeatureBitset MissingFeatures;

  auto Result =
      MatchInstructionImpl(Operands, Inst, ErrorInfo, MissingFeatures,
                           MatchingInlineAsm);

  switch (Result) {
  default:
    break;
  case Match_Success: {
    // Get the mnemonic for register pair validation
    StringRef Mnemonic;
    if (!Operands.empty()) {
      const V850Operand &Op = static_cast<const V850Operand &>(*Operands[0]);
      if (Op.isToken())
        Mnemonic = Op.getToken();
    }

    // Validate register pair constraints for double-precision FPU instructions
    if (validateFPURegisterPair(Mnemonic, Operands, IDLoc))
      return true;

    Inst.setLoc(IDLoc);
    Out.emitInstruction(Inst, getSTI());
    return false;
  }
  case Match_MissingFeature:
    return Error(IDLoc, "instruction requires a CPU feature not available");
  case Match_InvalidOperand: {
    SMLoc ErrorLoc = IDLoc;
    if (ErrorInfo != ~0ULL) {
      if (ErrorInfo >= Operands.size())
        return Error(ErrorLoc, "too few operands for instruction");
      ErrorLoc = ((V850Operand &)*Operands[ErrorInfo]).getStartLoc();
      if (ErrorLoc == SMLoc())
        ErrorLoc = IDLoc;
    }
    return Error(ErrorLoc, "invalid operand for instruction");
  }
  case Match_MnemonicFail:
    return Error(IDLoc, "unrecognized instruction mnemonic");
  }

  llvm_unreachable("Unknown match type detected!");
}

ParseStatus V850AsmParser::parseDirective(AsmToken DirectiveID) {
  return ParseStatus::NoMatch;
}

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void LLVMInitializeV850AsmParser() {
  RegisterMCAsmParser<V850AsmParser> X(getTheV850Target());
}
