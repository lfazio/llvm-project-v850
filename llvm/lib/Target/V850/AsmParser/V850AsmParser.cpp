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
#include "llvm/TargetParser/SubtargetFeature.h"
#include <cstdint>
#include <memory>

using namespace llvm;

// System register table entry - matches V850SystemOperands.td definition.
// Encoding is 10-bit: (selID << 5) | regID.
struct V850SysRegEntry {
  const char *Name;
  uint16_t Encoding;
  FeatureBitset FeaturesRequired;

  bool haveRequiredFeatures(const FeatureBitset &ActiveFeatures) const {
    return (FeaturesRequired & ActiveFeatures) == FeaturesRequired;
  }
};

namespace {
#define GET_V850SysRegsList_DECL
#define GET_V850SysRegsList_IMPL
#include "V850GenSearchableTables.inc"
} // anonymous namespace

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
  ParseStatus parseSystemRegister(OperandVector &Operands);

  /// Parse a double-precision FPU register operand.
  /// Accepts even GPR names (r0, r2, r6, r8, ...) and maps them to the
  /// corresponding DPR register pair (D0, D2, D6, D8, ...).
  ParseStatus parseDPRRegister(OperandVector &Operands);

  MCRegister matchRegisterName(StringRef Name);
  MCRegister matchRegisterAltName(StringRef Name);

  bool parseOperandWithModifier(OperandVector &Operands);

// Auto-generated instruction matching functions
#define GET_ASSEMBLER_HEADER
#include "V850GenAsmMatcher.inc"

  ParseStatus parseDirective(AsmToken DirectiveID) override;

  /// Validate register pair constraints for double-precision FPU instructions.
  /// Returns true if validation fails (odd register used where even required).

  /// Validate system register access based on CPU features.
  /// Returns true if validation fails (system register not available for CPU).
  bool validateSystemRegister(StringRef Mnemonic, const OperandVector &Operands,
                              SMLoc IDLoc);

public:
  // Auto-generated operand diagnostic types
  enum V850MatchResultTy {
    Match_Dummy = FIRST_TARGET_MATCH_RESULT_TY,
#define GET_OPERAND_DIAGNOSTIC_TYPES
#include "V850GenAsmMatcher.inc"
  };
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
  enum KindTy { K_Token, K_Register, K_Immediate, K_Memory } Kind;

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
  bool isDPRReg() const {
    if (!isReg())
      return false;
    MCRegister R = getReg();
    return R == V850::D0 || R == V850::D2 || R == V850::D4 || R == V850::D6 ||
           R == V850::D8 || R == V850::D10 || R == V850::D12 ||
           R == V850::D14 || R == V850::D16 || R == V850::D18 ||
           R == V850::D20 || R == V850::D22 || R == V850::D24 ||
           R == V850::D26 || R == V850::D28 || R == V850::D30;
  }
  bool isSysReg() const {
    if (!isImm())
      return false;
    if (const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(getImm()))
      return isUInt<10>(CE->getValue());
    return false;
  }

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

  bool isBrtarget9() const {
    if (!isImm())
      return false;
    if (const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(getImm()))
      return isInt<9>(CE->getValue()) && (CE->getValue() & 1) == 0;
    return true; // Symbolic: assume shortest form, relaxation handles overflow
  }

  bool isBrtarget16() const {
    if (!isImm())
      return false;
    if (const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(getImm()))
      return isInt<16>(CE->getValue()) && (CE->getValue() & 1) == 0;
    return true;
  }

  bool isBrtarget17() const {
    if (!isImm())
      return false;
    if (const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(getImm()))
      return isInt<17>(CE->getValue()) && (CE->getValue() & 1) == 0;
    return true;
  }

  bool isBrtarget22() const {
    if (!isImm())
      return false;
    if (const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(getImm()))
      return isInt<22>(CE->getValue()) && (CE->getValue() & 1) == 0;
    return true;
  }

  bool isBrtarget32() const {
    if (!isImm())
      return false;
    if (const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(getImm()))
      return isInt<32>(CE->getValue()) && (CE->getValue() & 1) == 0;
    return true;
  }
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

  static std::unique_ptr<V850Operand>
  createMem(MCRegister Base, const MCExpr *Disp, SMLoc S, SMLoc E) {
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

  void addBrtarget16Operands(MCInst &Inst, unsigned N) const {
    addImmOperands(Inst, N);
  }

  void addBrtarget17Operands(MCInst &Inst, unsigned N) const {
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

  void addSysRegOperands(MCInst &Inst, unsigned N) const {
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
  // Note: LDSR and STSR are handled entirely in parseInstruction because they
  // use FormatIX_SysReg (isCodeGenOnly=1) and require custom selID parsing.
  // MatchOperandParserImpl is not generated for isCodeGenOnly instructions.

  // Try the TableGen-driven custom operand parser first. This handles operands
  // like dprreg (double-precision FPU register pairs) that require the custom
  // parseDPRRegister() and parseSystemRegister() methods.
  {
    ParseStatus Res = MatchOperandParserImpl(Operands, Mnemonic,
                                             /*ParseForAllFeatures=*/true);
    if (Res.isSuccess())
      return ParseStatus::Success;
    if (Res.isFailure())
      return ParseStatus::Failure;
    // NoMatch — fall through to manual parsing below.
  }

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
  int CondVal =
      StringSwitch<int>(Name.lower())
          .Case("v", 0)   // Overflow
          .Case("c", 1)   // Carry / Lower
          .Case("l", 1)   // Lower (alias for c)
          .Case("z", 2)   // Zero / Equal
          .Case("e", 2)   // Equal (alias for z)
          .Case("nh", 3)  // Not higher
          .Case("n", 4)   // Negative
          .Case("t", 5)   // Always true (unconditional)
          .Case("lt", 6)  // Less than (signed)
          .Case("le", 7)  // Less or equal (signed)
          .Case("nv", 8)  // No overflow
          .Case("nc", 9)  // No carry / Not lower
          .Case("nl", 9)  // Not lower (alias for nc)
          .Case("nz", 10) // Not zero / Not equal
          .Case("ne", 10) // Not equal (alias for nz)
          .Case("h", 11)  // Higher
          .Case("p", 12)  // Positive
          .Case("sa", 13) // Saturated
          .Case("ge", 14) // Greater or equal (signed)
          .Case("gt", 15) // Greater than (signed)
          .Case("f", 5)   // Always false mapped to always true (same encoding)
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
                     .Case("f", 0)    // False
                     .Case("un", 1)   // Unordered
                     .Case("eq", 2)   // Equal
                     .Case("ueq", 3)  // Unordered or Equal
                     .Case("olt", 4)  // Ordered Less Than
                     .Case("ult", 5)  // Unordered or Less Than
                     .Case("ole", 6)  // Ordered Less or Equal
                     .Case("ule", 7)  // Unordered or Less or Equal
                     .Case("sf", 8)   // Signaling False
                     .Case("ngle", 9) // Not Greater, Less, or Equal
                     .Case("seq", 10) // Signaling Equal
                     .Case("ngl", 11) // Not Greater or Less
                     .Case("lt", 12)  // Less Than
                     .Case("nge", 13) // Not Greater or Equal
                     .Case("le", 14)  // Less or Equal
                     .Case("ngt", 15) // Not Greater Than
                     .Default(-1);

  if (FCondVal < 0)
    return ParseStatus::NoMatch;

  SMLoc EndLoc = Parser.getTok().getEndLoc();
  Parser.Lex(); // Consume the FP condition code token

  const MCExpr *Expr = MCConstantExpr::create(FCondVal, getContext());
  Operands.push_back(V850Operand::createImm(Expr, StartLoc, EndLoc));
  return ParseStatus::Success;
}

ParseStatus V850AsmParser::parseSystemRegister(OperandVector &Operands) {
  SMLoc StartLoc = Parser.getTok().getLoc();
  SMLoc EndLoc;

  switch (Parser.getTok().getKind()) {
  default:
    return ParseStatus::NoMatch;

  case AsmToken::Integer: {
    // Accept raw integer regID (0-31), optionally followed by ", selID" for
    // RH850G3M+ banked registers. Encoding = (selID << 5) | regID.
    int64_t RegID;
    if (Parser.getTok().getKind() != AsmToken::Integer)
      return ParseStatus::NoMatch;
    RegID = Parser.getTok().getIntVal();
    if (!isUInt<5>(RegID)) {
      Error(StartLoc, "system register ID must be in range [0, 31]");
      return ParseStatus::Failure;
    }
    Parser.Lex(); // Consume regID

    int64_t SelID = 0;
    // Check for optional ", selID" (RH850G3M+ banked register)
    if (Parser.getTok().getKind() == AsmToken::Comma) {
      Parser.Lex(); // Consume ','
      SMLoc SelLoc = Parser.getTok().getLoc();
      if (Parser.getTok().getKind() != AsmToken::Integer) {
        Error(SelLoc, "expected selID integer after ','");
        return ParseStatus::Failure;
      }
      SelID = Parser.getTok().getIntVal();
      if (!isUInt<5>(SelID)) {
        Error(SelLoc, "system register selID must be in range [0, 31]");
        return ParseStatus::Failure;
      }
      Parser.Lex(); // Consume selID
    }

    int64_t Enc = (SelID << 5) | RegID;
    EndLoc = Parser.getTok().getLoc();
    const MCExpr *Expr = MCConstantExpr::create(Enc, getContext());
    Operands.push_back(V850Operand::createImm(Expr, StartLoc, EndLoc));
    return ParseStatus::Success;
  }

  case AsmToken::Identifier: {
    StringRef Name = Parser.getTok().getString();

    // Look up system register by name; the table returns the 10-bit encoding.
    const V850SysRegEntry *SysReg = lookupV850SysRegByName(Name);
    if (!SysReg)
      return ParseStatus::NoMatch;

    EndLoc = Parser.getTok().getEndLoc();
    Parser.Lex(); // Consume the identifier

    const MCExpr *Expr = MCConstantExpr::create(SysReg->Encoding, getContext());
    Operands.push_back(V850Operand::createImm(Expr, StartLoc, EndLoc));
    return ParseStatus::Success;
  }
  }
}

ParseStatus V850AsmParser::parseDPRRegister(OperandVector &Operands) {
  SMLoc S = Parser.getTok().getLoc();

  if (!Parser.getTok().is(AsmToken::Identifier))
    return ParseStatus::NoMatch;

  StringRef Name = Parser.getTok().getString();

  // Match even GPR name to the corresponding DPR register pair.
  // Only even registers (r0, r2, r6, r8, r10, ...) have DPR counterparts.
  MCRegister GReg = matchRegisterName(Name);
  if (!GReg)
    return ParseStatus::NoMatch;

  MCRegister DReg;
  switch (GReg) {
  case V850::R0:
    DReg = V850::D0;
    break;
  case V850::R2:
    DReg = V850::D2;
    break;
  case V850::GP:
    DReg = V850::D4;
    break; // r4 = GP
  case V850::R6:
    DReg = V850::D6;
    break;
  case V850::R8:
    DReg = V850::D8;
    break;
  case V850::R10:
    DReg = V850::D10;
    break;
  case V850::R12:
    DReg = V850::D12;
    break;
  case V850::R14:
    DReg = V850::D14;
    break;
  case V850::R16:
    DReg = V850::D16;
    break;
  case V850::R18:
    DReg = V850::D18;
    break;
  case V850::R20:
    DReg = V850::D20;
    break;
  case V850::R22:
    DReg = V850::D22;
    break;
  case V850::R24:
    DReg = V850::D24;
    break;
  case V850::R26:
    DReg = V850::D26;
    break;
  case V850::R28:
    DReg = V850::D28;
    break;
  case V850::EP:
    DReg = V850::D30;
    break; // r30 = EP
  default:
    return Error(S, "double-precision FPU requires even-numbered register");
  }

  SMLoc E = Parser.getTok().getEndLoc();
  Parser.Lex();
  Operands.push_back(V850Operand::createReg(DReg, S, E));
  return ParseStatus::Success;
}

bool V850AsmParser::parseInstruction(ParseInstructionInfo &Info, StringRef Name,
                                     SMLoc NameLoc, OperandVector &Operands) {
  // Add the mnemonic as first operand
  Operands.push_back(V850Operand::createToken(Name, NameLoc));

  // If there are no operands, we're done
  if (Parser.getTok().is(AsmToken::EndOfStatement))
    return false;

  // LDSR/STSR use FormatIX_SysReg (isCodeGenOnly=1) and require custom parsing
  // because the optional selID placement differs per instruction:
  //   LDSR: ldsr reg2, regID [, selID]   OR   ldsr reg2, sysreg_name
  //   STSR: stsr regID, reg2 [, selID]   OR   stsr sysreg_name, reg2
  // For LDSR, selID follows regID directly; for STSR it follows reg2.
  if (Name.equals_insensitive("ldsr")) {
    // Parse reg2
    MCRegister Reg;
    SMLoc RegStart, RegEnd;
    if (!tryParseRegister(Reg, RegStart, RegEnd).isSuccess())
      return Error(Parser.getTok().getLoc(), "expected register for ldsr");
    Operands.push_back(V850Operand::createReg(Reg, RegStart, RegEnd));

    if (!Parser.getTok().is(AsmToken::Comma))
      return Error(Parser.getTok().getLoc(), "expected ',' for ldsr");
    Parser.Lex();

    // Parse sysreg: named OR integer regID [, selID]
    if (!parseSystemRegister(Operands).isSuccess())
      return Error(Parser.getTok().getLoc(),
                   "expected system register for ldsr");

    return false;
  }

  if (Name.equals_insensitive("stsr")) {
    SMLoc SysRegStart = Parser.getTok().getLoc();
    bool numericSysReg = false;
    int64_t RegID = 0;

    if (Parser.getTok().getKind() == AsmToken::Identifier) {
      // Named register: stsr sysreg_name, reg2
      if (!parseSystemRegister(Operands).isSuccess())
        return Error(SysRegStart, "expected system register for stsr");
    } else if (Parser.getTok().getKind() == AsmToken::Integer) {
      // Numeric form: stsr regID, reg2 [, selID]
      // Don't consume selID yet; it comes after reg2 for STSR.
      RegID = Parser.getTok().getIntVal();
      if (!isUInt<5>(RegID))
        return Error(SysRegStart,
                     "system register ID must be in range [0, 31]");
      Parser.Lex(); // Consume regID
      numericSysReg = true;
    } else {
      return Error(SysRegStart, "expected system register for stsr");
    }

    if (!Parser.getTok().is(AsmToken::Comma))
      return Error(Parser.getTok().getLoc(), "expected ',' for stsr");
    Parser.Lex();

    // Parse reg2
    MCRegister Reg;
    SMLoc RegStart, RegEnd;
    if (!tryParseRegister(Reg, RegStart, RegEnd).isSuccess())
      return Error(Parser.getTok().getLoc(), "expected register for stsr");

    // For numeric form, check for optional ', selID' after reg2
    int64_t SelID = 0;
    if (numericSysReg && Parser.getTok().is(AsmToken::Comma)) {
      Parser.Lex(); // Consume ','
      SMLoc SelLoc = Parser.getTok().getLoc();
      if (Parser.getTok().getKind() != AsmToken::Integer)
        return Error(SelLoc, "expected selID integer after ','");
      SelID = Parser.getTok().getIntVal();
      if (!isUInt<5>(SelID))
        return Error(SelLoc, "selID must be in range [0, 31]");
      Parser.Lex(); // Consume selID
    }

    if (numericSysReg) {
      int64_t Enc = (SelID << 5) | RegID;
      SMLoc SysRegEnd = RegStart;
      const MCExpr *Expr = MCConstantExpr::create(Enc, getContext());
      Operands.push_back(V850Operand::createImm(Expr, SysRegStart, SysRegEnd));
    }
    // If named register, parseSystemRegister already added it to Operands.

    Operands.push_back(V850Operand::createReg(Reg, RegStart, RegEnd));
    return false;
  }

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

bool V850AsmParser::validateSystemRegister(StringRef Mnemonic,
                                           const OperandVector &Operands,
                                           SMLoc IDLoc) {
  // Only validate LDSR and STSR instructions.
  if (!Mnemonic.equals_insensitive("ldsr") &&
      !Mnemonic.equals_insensitive("stsr"))
    return false;

  // Get the system register operand.
  // LDSR: ldsr reg2, sysreg -> Operands[0]=mnemonic, [1]=reg2, [2]=sysreg
  // STSR: stsr sysreg, reg2 -> Operands[0]=mnemonic, [1]=sysreg, [2]=reg2
  unsigned SysRegOpIdx = Mnemonic.equals_insensitive("ldsr") ? 2 : 1;

  if (SysRegOpIdx >= Operands.size())
    return false;

  const V850Operand &SysRegOp =
      static_cast<const V850Operand &>(*Operands[SysRegOpIdx]);
  if (!SysRegOp.isImm())
    return false;

  const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(SysRegOp.getImm());
  if (!CE)
    return false;

  int64_t Enc = CE->getValue(); // 10-bit: (selID << 5) | regID

  // Check CPU feature requirements based on the 10-bit encoding.
  const FeatureBitset &Features = STI.getFeatureBits();

  // Look up by 10-bit encoding to find feature requirements.
  auto Range = lookupV850SysRegByEncoding(Enc);
  for (const auto &SysReg : Range) {
    if (SysReg.haveRequiredFeatures(Features))
      return false; // Found a matching register with satisfied features.
  }
  // If we found entries but none matched features, report an error.
  if (Range.begin() != Range.end()) {
    // Determine which CPU variant is needed from the feature requirements.
    const auto &FirstReg = *Range.begin();
    StringRef CPUName;
    if (FirstReg.FeaturesRequired[V850::FeatureRH850G3M])
      CPUName = "RH850G3M";
    else if (FirstReg.FeaturesRequired[V850::FeatureV850E2M])
      CPUName = "V850E2M";
    else if (FirstReg.FeaturesRequired[V850::FeatureV850E2])
      CPUName = "V850E2";
    else if (FirstReg.FeaturesRequired[V850::FeatureV850E1])
      CPUName = "V850E1";
    else if (FirstReg.FeaturesRequired[V850::FeatureV850FPU])
      CPUName = "V850E2M with FPU";
    else
      CPUName = "unknown";

    Error(SysRegOp.getStartLoc(),
          "system register requires " + CPUName + " or later CPU");
    return true;
  }

  // No named register found for this encoding, but raw encoding is valid.
  return false;
}

bool V850AsmParser::matchAndEmitInstruction(SMLoc IDLoc, unsigned &Opcode,
                                            OperandVector &Operands,
                                            MCStreamer &Out,
                                            uint64_t &ErrorInfo,
                                            bool MatchingInlineAsm) {
  MCInst Inst;
  FeatureBitset MissingFeatures;

  // Handle LDSR/STSR manually: they use FormatIX_SysReg (isCodeGenOnly=1) and
  // are not in the AsmMatcher table. The operand vector is:
  //   LDSR: [token "ldsr", reg2, sysreg_imm]
  //   STSR: [token "stsr", sysreg_imm, reg2]
  // The MCInst operand order is [reg2, sysreg_imm] for both (outputs first).
  {
    StringRef Mnemonic;
    if (!Operands.empty()) {
      const V850Operand &Op = static_cast<const V850Operand &>(*Operands[0]);
      if (Op.isToken())
        Mnemonic = Op.getToken();
    }
    if (Mnemonic.equals_insensitive("ldsr") ||
        Mnemonic.equals_insensitive("stsr")) {
      if (Operands.size() != 3)
        return Error(IDLoc, "expected 2 operands for " + Mnemonic);

      if (validateSystemRegister(Mnemonic, Operands, IDLoc))
        return true;

      if (Mnemonic.equals_insensitive("ldsr")) {
        const V850Operand &Reg2Op =
            static_cast<const V850Operand &>(*Operands[1]);
        const V850Operand &SysRegOp =
            static_cast<const V850Operand &>(*Operands[2]);
        if (!Reg2Op.isReg() || !SysRegOp.isImm())
          return Error(IDLoc, "invalid operands for ldsr");
        const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(SysRegOp.getImm());
        Inst.setOpcode(V850::LDSR);
        Inst.addOperand(MCOperand::createReg(Reg2Op.getReg()));
        Inst.addOperand(MCOperand::createImm(CE ? CE->getValue() : 0));
      } else {
        // STSR: operands are [sysreg_imm, reg2]; MCInst wants [reg2, sysreg].
        const V850Operand &SysRegOp =
            static_cast<const V850Operand &>(*Operands[1]);
        const V850Operand &Reg2Op =
            static_cast<const V850Operand &>(*Operands[2]);
        if (!SysRegOp.isImm() || !Reg2Op.isReg())
          return Error(IDLoc, "invalid operands for stsr");
        const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(SysRegOp.getImm());
        Inst.setOpcode(V850::STSR);
        Inst.addOperand(MCOperand::createReg(Reg2Op.getReg()));
        Inst.addOperand(MCOperand::createImm(CE ? CE->getValue() : 0));
      }
      Inst.setLoc(IDLoc);
      Out.emitInstruction(Inst, getSTI());
      return false;
    }
  }

  auto Result = MatchInstructionImpl(Operands, Inst, ErrorInfo, MissingFeatures,
                                     MatchingInlineAsm);

  switch (Result) {
  default:
    break;
  case Match_Success: {
    // Validate system register access based on CPU features
    StringRef Mnemonic;
    if (!Operands.empty()) {
      const V850Operand &Op = static_cast<const V850Operand &>(*Operands[0]);
      if (Op.isToken())
        Mnemonic = Op.getToken();
    }
    if (validateSystemRegister(Mnemonic, Operands, IDLoc))
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
  case Match_InvalidSysReg:
    return Error(IDLoc, "invalid system register name or ID");
  }

  llvm_unreachable("Unknown match type detected!");
}

ParseStatus V850AsmParser::parseDirective(AsmToken DirectiveID) {
  return ParseStatus::NoMatch;
}

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void
LLVMInitializeV850AsmParser() {
  RegisterMCAsmParser<V850AsmParser> X(getTheV850Target());
}
