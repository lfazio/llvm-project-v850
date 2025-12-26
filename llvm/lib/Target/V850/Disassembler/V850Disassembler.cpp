//===-- V850Disassembler.cpp - Disassembler for V850 ----------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements the V850Disassembler class.
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/V850MCTargetDesc.h"
#include "TargetInfo/V850TargetInfo.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCDecoderOps.h"
#include "llvm/MC/MCDisassembler/MCDisassembler.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Compiler.h"
#include "llvm/Support/Endian.h"
#include "llvm/Support/MathExtras.h"

using namespace llvm;

#define DEBUG_TYPE "v850-disassembler"

typedef MCDisassembler::DecodeStatus DecodeStatus;

namespace {
class V850Disassembler : public MCDisassembler {
public:
  V850Disassembler(const MCSubtargetInfo &STI, MCContext &Ctx)
      : MCDisassembler(STI, Ctx) {}

  DecodeStatus getInstruction(MCInst &Instr, uint64_t &Size,
                              ArrayRef<uint8_t> Bytes, uint64_t Address,
                              raw_ostream &CStream) const override;
};
} // end anonymous namespace

static MCDisassembler *createV850Disassembler(const Target &T,
                                               const MCSubtargetInfo &STI,
                                               MCContext &Ctx) {
  return new V850Disassembler(STI, Ctx);
}

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void LLVMInitializeV850Disassembler() {
  TargetRegistry::RegisterMCDisassembler(getTheV850Target(),
                                         createV850Disassembler);
}

//===----------------------------------------------------------------------===//
// Register Decoders
//===----------------------------------------------------------------------===//

// Lookup table mapping hardware encoding (0-31) to register enum values
static const MCPhysReg GPRDecoderTable[] = {
  V850::R0,  V850::R1,  V850::R2,  V850::SP,
  V850::GP,  V850::TP,  V850::R6,  V850::R7,
  V850::R8,  V850::R9,  V850::R10, V850::R11,
  V850::R12, V850::R13, V850::R14, V850::R15,
  V850::R16, V850::R17, V850::R18, V850::R19,
  V850::R20, V850::R21, V850::R22, V850::R23,
  V850::R24, V850::R25, V850::R26, V850::R27,
  V850::R28, V850::R29, V850::EP,  V850::LP
};

static DecodeStatus DecodeGPRRegisterClass(MCInst &Inst, uint32_t RegNo,
                                            uint64_t Address,
                                            const MCDisassembler *Decoder) {
  if (RegNo >= 32)
    return MCDisassembler::Fail;

  MCRegister Reg = GPRDecoderTable[RegNo];
  Inst.addOperand(MCOperand::createReg(Reg));
  return MCDisassembler::Success;
}

static DecodeStatus DecodeGPRnoR0RegisterClass(MCInst &Inst, uint32_t RegNo,
                                                uint64_t Address,
                                                const MCDisassembler *Decoder) {
  if (RegNo == 0 || RegNo >= 32)
    return MCDisassembler::Fail;

  MCRegister Reg = GPRDecoderTable[RegNo];
  Inst.addOperand(MCOperand::createReg(Reg));
  return MCDisassembler::Success;
}

static DecodeStatus DecodeSysRegRegisterClass(MCInst &Inst, uint32_t RegNo,
                                               uint64_t Address,
                                               const MCDisassembler *Decoder) {
  // System registers have a different encoding
  // For now, just add the register number as immediate
  if (RegNo >= 32)
    return MCDisassembler::Fail;

  // Map system register number to actual register
  // TODO: Add proper system register handling
  Inst.addOperand(MCOperand::createImm(RegNo));
  return MCDisassembler::Success;
}

//===----------------------------------------------------------------------===//
// Immediate Decoders
//===----------------------------------------------------------------------===//

template <unsigned N>
static DecodeStatus decodeUImmOperand(MCInst &Inst, uint32_t Imm,
                                       int64_t Address,
                                       const MCDisassembler *Decoder) {
  assert(isUInt<N>(Imm) && "Invalid immediate");
  Inst.addOperand(MCOperand::createImm(Imm));
  return MCDisassembler::Success;
}

template <unsigned N>
static DecodeStatus decodeSImm(MCInst &Inst, uint32_t Imm,
                                int64_t Address,
                                const MCDisassembler *Decoder) {
  assert(isUInt<N>(Imm) && "Invalid immediate");
  // Sign-extend the number in the bottom N bits of Imm
  Inst.addOperand(MCOperand::createImm(SignExtend64<N>(Imm)));
  return MCDisassembler::Success;
}

//===----------------------------------------------------------------------===//
// Branch Target Decoders
//===----------------------------------------------------------------------===//

static DecodeStatus decodeBranchTarget9(MCInst &Inst, uint32_t Imm,
                                         int64_t Address,
                                         const MCDisassembler *Decoder) {
  // 9-bit signed offset, bit 0 is implicitly 0
  // The encoding stores bits [8:1], so we need to shift left by 1
  int32_t Offset = SignExtend32<9>(Imm << 1);
  Inst.addOperand(MCOperand::createImm(Offset));
  return MCDisassembler::Success;
}

static DecodeStatus decodeBranchTarget22(MCInst &Inst, uint32_t Imm,
                                          int64_t Address,
                                          const MCDisassembler *Decoder) {
  // 22-bit signed offset, bit 0 is implicitly 0
  // The encoding stores bits [21:1], so we need to shift left by 1
  int32_t Offset = SignExtend32<22>(Imm << 1);
  Inst.addOperand(MCOperand::createImm(Offset));
  return MCDisassembler::Success;
}

static DecodeStatus decodeBranchTarget32(MCInst &Inst, uint32_t Imm,
                                          int64_t Address,
                                          const MCDisassembler *Decoder) {
  // 32-bit signed offset, bit 0 is implicitly 0
  // The encoding stores bits [31:1], so we need to shift left by 1
  int32_t Offset = Imm << 1;
  Inst.addOperand(MCOperand::createImm(Offset));
  return MCDisassembler::Success;
}

//===----------------------------------------------------------------------===//
// Decoder Table
//===----------------------------------------------------------------------===//

#include "V850GenDisassemblerTables.inc"

//===----------------------------------------------------------------------===//
// V850Disassembler::getInstruction
//===----------------------------------------------------------------------===//

DecodeStatus V850Disassembler::getInstruction(MCInst &MI, uint64_t &Size,
                                               ArrayRef<uint8_t> Bytes,
                                               uint64_t Address,
                                               raw_ostream &CS) const {
  // V850 uses little-endian byte ordering
  // Instructions are either 16-bit or 32-bit

  if (Bytes.size() < 2) {
    Size = 0;
    return MCDisassembler::Fail;
  }

  // Read the first 16-bit halfword
  uint16_t Insn16 = support::endian::read16le(Bytes.data());

  // Try to decode as a 32-bit instruction first if we have enough bytes
  // V850 32-bit instructions are determined by specific opcode patterns
  if (Bytes.size() >= 4) {
    // Read the full 32-bit instruction
    uint32_t Insn32 = support::endian::read32le(Bytes.data());

    // Try 32-bit decoder table
    MI.clear();
    DecodeStatus Result = decodeInstruction(DecoderTable32, MI, Insn32,
                                            Address, this, STI);
    if (Result != MCDisassembler::Fail) {
      Size = 4;
      return Result;
    }
  }

  // Try to decode as a 16-bit instruction
  MI.clear();
  DecodeStatus Result = decodeInstruction(DecoderTable16, MI, Insn16,
                                          Address, this, STI);
  if (Result != MCDisassembler::Fail) {
    Size = 2;
    return Result;
  }

  Size = 2;  // Consume at least 2 bytes on failure
  return MCDisassembler::Fail;
}
