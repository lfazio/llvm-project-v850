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

  MCRegister matchRegisterName(StringRef Name);
  MCRegister matchRegisterAltName(StringRef Name);

  bool parseOperandWithModifier(OperandVector &Operands);

// Auto-generated instruction matching functions
#define GET_ASSEMBLER_HEADER
#include "V850GenAsmMatcher.inc"

  ParseStatus parseDirective(AsmToken DirectiveID) override;

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

  bool isBrtarget9() const { return isImm(); }
  bool isBrtarget22() const { return isImm(); }
  bool isCondcode() const { return isImm(); }

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

  void addCondcodeOperands(MCInst &Inst, unsigned N) const {
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

  // Check for memory operand starting with '[' (no displacement)
  if (getLexer().is(AsmToken::LBrac)) {
    return parseMemoryOperand(Operands);
  }

  // Try to parse as an immediate expression
  StartLoc = Parser.getTok().getLoc();
  const MCExpr *Expr;
  if (Parser.parseExpression(Expr))
    return ParseStatus::Failure;

  EndLoc = Parser.getTok().getLoc();

  // Check if this is a memory operand: disp[reg]
  // The AsmMatcher expects: Imm(disp), '[' token, Reg, ']' token
  if (getLexer().is(AsmToken::LBrac)) {
    // Add the displacement immediate first
    Operands.push_back(V850Operand::createImm(Expr, StartLoc, EndLoc));

    // Add '[' token
    SMLoc LBracLoc = Parser.getTok().getLoc();
    Operands.push_back(V850Operand::createToken("[", LBracLoc));
    Parser.Lex(); // Consume '['

    // Parse base register
    MCRegister BaseReg;
    SMLoc RegStart, RegEnd;
    if (!tryParseRegister(BaseReg, RegStart, RegEnd).isSuccess()) {
      Error(Parser.getTok().getLoc(), "expected register");
      return ParseStatus::Failure;
    }
    Operands.push_back(V850Operand::createReg(BaseReg, RegStart, RegEnd));

    // Expect ']'
    if (Parser.getTok().isNot(AsmToken::RBrac)) {
      Error(Parser.getTok().getLoc(), "expected ']'");
      return ParseStatus::Failure;
    }
    SMLoc RBracLoc = Parser.getTok().getLoc();
    Operands.push_back(V850Operand::createToken("]", RBracLoc));
    Parser.Lex(); // Consume ']'

    return ParseStatus::Success;
  }

  // Just an immediate
  Operands.push_back(V850Operand::createImm(Expr, StartLoc, EndLoc));
  return ParseStatus::Success;
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
  // This handles the [reg] case (e.g., for JMP instruction)
  // The AsmMatcher expects: '[' token, Reg, ']' token

  // Expect '['
  if (Parser.getTok().isNot(AsmToken::LBrac)) {
    Error(Parser.getTok().getLoc(), "expected '['");
    return ParseStatus::Failure;
  }
  SMLoc LBracLoc = Parser.getTok().getLoc();
  Operands.push_back(V850Operand::createToken("[", LBracLoc));
  Parser.Lex(); // Consume '['

  // Parse base register
  MCRegister BaseReg;
  SMLoc RegStart, RegEnd;
  if (!tryParseRegister(BaseReg, RegStart, RegEnd).isSuccess()) {
    Error(Parser.getTok().getLoc(), "expected register");
    return ParseStatus::Failure;
  }
  Operands.push_back(V850Operand::createReg(BaseReg, RegStart, RegEnd));

  // Expect ']'
  if (Parser.getTok().isNot(AsmToken::RBrac)) {
    Error(Parser.getTok().getLoc(), "expected ']'");
    return ParseStatus::Failure;
  }
  SMLoc RBracLoc = Parser.getTok().getLoc();
  Operands.push_back(V850Operand::createToken("]", RBracLoc));
  Parser.Lex(); // Consume ']'

  return ParseStatus::Success;
}

ParseStatus V850AsmParser::parseBranchTarget(OperandVector &Operands) {
  return parseImmediate(Operands);
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
  case Match_Success:
    Inst.setLoc(IDLoc);
    Out.emitInstruction(Inst, getSTI());
    return false;
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
