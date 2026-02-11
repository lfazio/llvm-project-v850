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
  DecodeStatus getInstruction16(MCInst &Instr, uint64_t &Size,
                                ArrayRef<uint8_t> Bytes, uint64_t Address,
                                raw_ostream &CStream) const;
  DecodeStatus getInstruction32(MCInst &Instr, uint64_t &Size,
                                ArrayRef<uint8_t> Bytes, uint64_t Address,
                                raw_ostream &CStream) const;
  DecodeStatus getInstruction48(MCInst &Instr, uint64_t &Size,
                                ArrayRef<uint8_t> Bytes, uint64_t Address,
                                raw_ostream &CStream) const;
};
} // end anonymous namespace

static MCDisassembler *createV850Disassembler(const Target &T,
                                              const MCSubtargetInfo &STI,
                                              MCContext &Ctx) {
  return new V850Disassembler(STI, Ctx);
}

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void
LLVMInitializeV850Disassembler() {
  TargetRegistry::RegisterMCDisassembler(getTheV850Target(),
                                         createV850Disassembler);
}

//===----------------------------------------------------------------------===//
// Register Decoders
//===----------------------------------------------------------------------===//

// Lookup table mapping hardware encoding (0-31) to register enum values
static const MCPhysReg GPRDecoderTable[] = {
    V850::R0,  V850::R1,  V850::R2,  V850::SP,  V850::GP,  V850::TP,  V850::R6,
    V850::R7,  V850::R8,  V850::R9,  V850::R10, V850::R11, V850::R12, V850::R13,
    V850::R14, V850::R15, V850::R16, V850::R17, V850::R18, V850::R19, V850::R20,
    V850::R21, V850::R22, V850::R23, V850::R24, V850::R25, V850::R26, V850::R27,
    V850::R28, V850::R29, V850::EP,  V850::LP};

static DecodeStatus DecodeGPRRegisterClass(MCInst &Inst, uint32_t RegNo,
                                           uint64_t Address,
                                           const MCDisassembler *Decoder) {
  if (RegNo >= 32)
    return MCDisassembler::Fail;

  MCRegister Reg = GPRDecoderTable[RegNo];
  Inst.addOperand(MCOperand::createReg(Reg));
  return MCDisassembler::Success;
}

// FPR uses the same physical registers as GPR
static DecodeStatus DecodeFPRRegisterClass(MCInst &Inst, uint32_t RegNo,
                                           uint64_t Address,
                                           const MCDisassembler *Decoder) {
  if (RegNo >= 32)
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
static DecodeStatus decodeSImm(MCInst &Inst, uint32_t Imm, int64_t Address,
                               const MCDisassembler *Decoder) {
  assert(isUInt<N>(Imm) && "Invalid immediate");
  // Sign-extend the number in the bottom N bits of Imm
  Inst.addOperand(MCOperand::createImm(SignExtend64<N>(Imm)));
  return MCDisassembler::Success;
}

//===----------------------------------------------------------------------===//
// Custom Instruction Decoders
// These handle encoding conflicts between instructions
//===----------------------------------------------------------------------===//

// Custom decoder for SLDBU to avoid conflict with JMP [reg1].
// When reg2=0 (bits[15:11]=0), this could be JMP, so we return Fail to
// allow the decoder to try JMP next.
static DecodeStatus DecodeSLDBUInstruction(MCInst &Inst, uint32_t Insn,
                                           uint64_t Address,
                                           const MCDisassembler *Decoder) {
  // Extract reg2 from bits [15:11]
  unsigned Reg2 = (Insn >> 11) & 0x1F;

  // If reg2 is 0, this encoding conflicts with JMP - return Fail to allow
  // the decoder to try JMP instead
  if (Reg2 == 0)
    return MCDisassembler::Fail;

  // Extract disp4 from bits [3:0]
  unsigned Disp4 = Insn & 0xF;

  // Add the register operand
  Inst.addOperand(MCOperand::createReg(GPRDecoderTable[Reg2]));

  // Add the displacement operand (already in byte units for SLDBU)
  Inst.addOperand(MCOperand::createImm(Disp4));

  return MCDisassembler::Success;
}

// Custom decoder for SLDHU to avoid conflict with JMP [reg1].
// When reg2=0 (bits[15:11]=0), this could be JMP, so we return Fail to
// allow the decoder to try JMP next.
static DecodeStatus DecodeSLDHUInstruction(MCInst &Inst, uint32_t Insn,
                                           uint64_t Address,
                                           const MCDisassembler *Decoder) {
  // Extract reg2 from bits [15:11]
  unsigned Reg2 = (Insn >> 11) & 0x1F;

  // If reg2 is 0, this encoding conflicts with JMP - return Fail to allow
  // the decoder to try JMP instead
  if (Reg2 == 0)
    return MCDisassembler::Fail;

  // Extract disp4 from bits [3:0] - this is disp5[4:1]
  unsigned Disp4 = Insn & 0xF;

  // Add the register operand
  Inst.addOperand(MCOperand::createReg(GPRDecoderTable[Reg2]));

  // Add the displacement operand (multiply by 2 to get byte offset)
  Inst.addOperand(MCOperand::createImm(Disp4 * 2));

  return MCDisassembler::Success;
}

//===----------------------------------------------------------------------===//
// Branch Target Decoders
//===----------------------------------------------------------------------===//

static DecodeStatus decodeBranchTarget9(MCInst &Inst, uint32_t Imm,
                                        int64_t Address,
                                        const MCDisassembler *Decoder) {
  // Imm is the 8-bit half-displacement (displacement >> 1)
  // Sign-extend from 8 bits and shift left by 1 to recover the byte offset
  int32_t Offset = SignExtend32<8>(Imm) << 1;
  Inst.addOperand(MCOperand::createImm(Offset));
  return MCDisassembler::Success;
}

static DecodeStatus decodeBranchTarget16(MCInst &Inst, uint32_t Imm,
                                         int64_t Address,
                                         const MCDisassembler *Decoder) {
  // Imm is the 15-bit half-displacement (displacement >> 1)
  // Sign-extend from 15 bits and shift left by 1 to recover the byte offset
  int32_t Offset = SignExtend32<15>(Imm) << 1;
  Inst.addOperand(MCOperand::createImm(Offset));
  return MCDisassembler::Success;
}

static DecodeStatus decodeBranchTarget17(MCInst &Inst, uint32_t Imm,
                                         int64_t Address,
                                         const MCDisassembler *Decoder) {
  // Imm is the 16-bit half-displacement (displacement >> 1)
  // Sign-extend from 16 bits and shift left by 1 to recover the byte offset
  int32_t Offset = SignExtend32<16>(Imm) << 1;
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
// Note: V850MCTargetDesc.h already includes GET_SUBTARGETINFO_ENUM
//===----------------------------------------------------------------------===//

#include "V850GenDisassemblerTables.inc"

//===----------------------------------------------------------------------===//
// V850Disassembler::getInstruction
//===----------------------------------------------------------------------===//

DecodeStatus V850Disassembler::getInstruction16(MCInst &MI, uint64_t &Size,
                                                ArrayRef<uint8_t> Bytes,
                                                uint64_t Address,
                                                raw_ostream &CS) const {
  if (Bytes.size() < 2) {
    Size = 0;
    return MCDisassembler::Fail;
  }
  uint16_t Insn16 = support::endian::read16le(Bytes.data());

  bool HasRH850G3M = STI.hasFeature(V850::FeatureRH850G3M);
  bool HasV850E2M = STI.hasFeature(V850::FeatureV850E2M);
  bool HasV850E1 = STI.hasFeature(V850::FeatureV850E1);

  // Try RH850G3M-specific instructions first (superset of V850E2M)
  if (HasRH850G3M) {
    MI.clear();
    DecodeStatus Result = decodeInstruction(DecoderTableRH850G3M16, MI, Insn16,
                                            Address, this, STI);
    if (Result != MCDisassembler::Fail) {
      Size = 2;
      return Result;
    }
  }

  // Try V850E2M-specific instructions (superset of V850E1)
  if (HasV850E2M) {
    MI.clear();
    DecodeStatus Result = decodeInstruction(DecoderTableV850E2M16, MI, Insn16,
                                            Address, this, STI);
    if (Result != MCDisassembler::Fail) {
      Size = 2;
      return Result;
    }
  }

  // Try V850E1-specific instructions (includes SLDBU, SLDHU with custom
  // decoders that return Fail for reg2=0 to allow fallthrough to JMP)
  if (HasV850E1) {
    MI.clear();
    DecodeStatus Result =
        decodeInstruction(DecoderTableV850E116, MI, Insn16, Address, this, STI);
    if (Result != MCDisassembler::Fail) {
      Size = 2;
      return Result;
    }
  }

  // Try base V850 instructions
  MI.clear();
  DecodeStatus Result =
      decodeInstruction(DecoderTable16, MI, Insn16, Address, this, STI);
  if (Result != MCDisassembler::Fail) {
    Size = 2;
    return Result;
  }

  return MCDisassembler::Fail;
}

DecodeStatus V850Disassembler::getInstruction32(MCInst &MI, uint64_t &Size,
                                                ArrayRef<uint8_t> Bytes,
                                                uint64_t Address,
                                                raw_ostream &CS) const {
  if (Bytes.size() < 4) {
    Size = 0;
    return MCDisassembler::Fail;
  }
  uint32_t Insn32 = support::endian::read32le(Bytes.data());

  bool HasRH850G3M = STI.hasFeature(V850::FeatureRH850G3M);
  bool HasV850E2M = STI.hasFeature(V850::FeatureV850E2M);

  // Try RH850G3M-specific instructions first (superset of V850E2M)
  if (HasRH850G3M) {
    MI.clear();
    DecodeStatus Result = decodeInstruction(DecoderTableRH850G3M32, MI, Insn32,
                                            Address, this, STI);
    if (Result != MCDisassembler::Fail) {
      Size = 4;
      return Result;
    }
  }

  // Try base 32-bit decoder; this favors integer instructions that
  // otherwise can be mis-decoded by the E2M table (which contains FPU
  // encodings that overlap extended opcode patterns).
  MI.clear();
  DecodeStatus Result =
      decodeInstruction(DecoderTable32, MI, Insn32, Address, this, STI);
  if (Result != MCDisassembler::Fail) {
    Size = 4;
    return Result;
  }

  if (HasV850E2M) {
    MI.clear();
    DecodeStatus Result2 = decodeInstruction(DecoderTableV850E2M32, MI, Insn32,
                                             Address, this, STI);
    if (Result2 != MCDisassembler::Fail) {
      Size = 4;
      return Result2;
    }
  }

  return MCDisassembler::Fail;
}

DecodeStatus V850Disassembler::getInstruction48(MCInst &MI, uint64_t &Size,
                                                ArrayRef<uint8_t> Bytes,
                                                uint64_t Address,
                                                raw_ostream &CS) const {
  // 48-bit decoders are not generated by default in this target layout.
  // If in future a DecoderTable48 is added, implement similar logic as
  // for 16/32-bit. For now, read bytes to check availability and fail.
  if (Bytes.size() < 6) {
    Size = 0;
    return MCDisassembler::Fail;
  }

  // build little-endian 48-bit value
  uint64_t Insn = 0;
  for (size_t i = 0; i < 6; ++i)
    Insn |= (uint64_t)Bytes[i] << (8 * i);

  // No decoder table available; indicate failure.
  return MCDisassembler::Fail;
}

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

  unsigned Opcode6 = (Insn16 >> 5) & 0x3F;
  unsigned Reg2 = (Insn16 >> 11) & 0x1F;

  // Check for 48-bit MOVi32 instruction (V850E1+)
  // MOVi32 uses opcode=0x31 (same as MOVEA) but with reg2=0
  // This distinguishes MOVi32 from MOVEA (which has reg2 != 0)
  if (Opcode6 == 0x31 && Reg2 == 0 && Bytes.size() >= 6) {
    if (STI.hasFeature(V850::FeatureV850E1)) {
      // Format VI-E1: 48-bit MOV imm32, reg1
      // Bits 4-0: reg1
      // Bits 10-5: opcode (0x31)
      // Bits 15-11: reg2 (must be 0)
      // Bits 31-16: imm32[15:0]
      // Bits 47-32: imm32[31:16]
      unsigned Reg1 = Insn16 & 0x1F;
      uint16_t ImmLo = support::endian::read16le(Bytes.data() + 2);
      uint16_t ImmHi = support::endian::read16le(Bytes.data() + 4);
      uint32_t Imm32 = (static_cast<uint32_t>(ImmHi) << 16) | ImmLo;

      MI.setOpcode(V850::MOVi32);
      MI.addOperand(MCOperand::createReg(GPRDecoderTable[Reg1]));
      MI.addOperand(MCOperand::createImm(static_cast<int32_t>(Imm32)));
      Size = 6;
      return MCDisassembler::Success;
    }
  }

  // Decide whether to try 16-bit or 32-bit first using a small heuristic.
  // Many 32-bit V850 formats use the extended opcode value 0b111111 in
  // bits [10:5] of the first halfword (FormatIX/XI/XII/etc.). If those
  // bits are 0b111111, prefer the 32-bit decoder first.
  //
  // Also, Format V (JR/JARL) has opcode 0b101111 in bits [10:5]. The first
  // halfword happens to match Format III (Bcond) pattern because bits[10:7]
  // equals 0b1011 (branch opcode), so we need to prefer 32-bit for Format V.

  bool Prefer32 = (Opcode6 == 0x3F) || // Extended opcode
                  (Opcode6 == 0x2F);   // JR/JARL (Format V)

  if (Prefer32 && Bytes.size() >= 4) {
    DecodeStatus R = getInstruction32(MI, Size, Bytes, Address, CS);
    if (R != MCDisassembler::Fail)
      return R;
    // fallthrough to try 16-bit
  }

  // Try 16-bit decoders first (including E2M variant)
  DecodeStatus R16 = getInstruction16(MI, Size, Bytes, Address, CS);
  if (R16 != MCDisassembler::Fail)
    return R16;

  // If we didn't prefer 32 above and we have enough bytes, try 32-bit as a
  // recovery path.
  if (!Prefer32 && Bytes.size() >= 4) {
    DecodeStatus R32 = getInstruction32(MI, Size, Bytes, Address, CS);
    if (R32 != MCDisassembler::Fail)
      return R32;
  }

  // On failure, consume at least 2 bytes so the disassembler can progress.
  Size = 2;
  return MCDisassembler::Fail;
}
