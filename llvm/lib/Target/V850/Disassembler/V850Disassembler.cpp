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

// DPR uses even/odd GPR pairs: D0=(R0,R1), D2=(R2,SP), ..., D30=(EP,LP)
// RegNo is the even GPR number (0, 2, 4, ..., 30).
static const MCPhysReg DPRDecoderTable[] = {
    V850::D0,  V850::D2,  V850::D4,  V850::D6,  V850::D8,  V850::D10,
    V850::D12, V850::D14, V850::D16, V850::D18, V850::D20, V850::D22,
    V850::D24, V850::D26, V850::D28, V850::D30,
};

static DecodeStatus DecodeDPRRegisterClass(MCInst &Inst, uint32_t RegNo,
                                           uint64_t Address,
                                           const MCDisassembler *Decoder) {
  // Only even register numbers are valid for double-precision pairs.
  if (RegNo >= 32 || (RegNo & 1) != 0)
    return MCDisassembler::Fail;

  MCRegister Reg = DPRDecoderTable[RegNo >> 1];
  Inst.addOperand(MCOperand::createReg(Reg));
  return MCDisassembler::Success;
}

static DecodeStatus decodeSystemRegister(MCInst &Inst, uint32_t Enc,
                                         int64_t Address,
                                         const MCDisassembler *Decoder) {
  // Enc is the combined 10-bit sysreg encoding: (selID << 5) | regID.
  // The auto-generated decoder reconstructs this from bits[4:0] (regID) and
  // bits[20:16] (selID) of the instruction. Validate the 10-bit range.
  if (Enc >= 1024)
    return MCDisassembler::Fail;

  Inst.addOperand(MCOperand::createImm(Enc));
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
// Post-Increment Load/Store Decoders (RH850G4MH+)
//===----------------------------------------------------------------------===//

// Custom decoder for post-increment/decrement load instructions.
// These have 2 outputs: reg3 (loaded data) and wb (writeback = reg1).
// Format: dir[15:11] 111111[10:5] reg1[4:0] | reg3[31:27] 011011[26:21]
// subid[20:16]
static DecodeStatus
DecodePostIncLoadInstruction(MCInst &MI, uint32_t Insn, uint64_t Address,
                             const MCDisassembler *Decoder) {
  unsigned Reg3 = (Insn >> 27) & 0x1F;
  unsigned Reg1 = Insn & 0x1F;

  if (Reg3 >= 32 || Reg1 >= 32)
    return MCDisassembler::Fail;

  // Output 0: reg3 (loaded data)
  MI.addOperand(MCOperand::createReg(GPRDecoderTable[Reg3]));
  // Output 1: wb (writeback, tied to reg1)
  MI.addOperand(MCOperand::createReg(GPRDecoderTable[Reg1]));
  // Input 0: reg1 (base address)
  MI.addOperand(MCOperand::createReg(GPRDecoderTable[Reg1]));

  return MCDisassembler::Success;
}

// Custom decoder for post-increment/decrement store instructions.
// These have 1 output: wb (writeback = reg1), and 2 inputs: reg3, reg1.
// Format: dir[15:11] 111111[10:5] reg1[4:0] | reg3[31:27] 011011[26:21]
// subid[20:16]
static DecodeStatus
DecodePostIncStoreInstruction(MCInst &MI, uint32_t Insn, uint64_t Address,
                              const MCDisassembler *Decoder) {
  unsigned Reg3 = (Insn >> 27) & 0x1F;
  unsigned Reg1 = Insn & 0x1F;

  if (Reg3 >= 32 || Reg1 >= 32)
    return MCDisassembler::Fail;

  // Output 0: wb (writeback, tied to reg1)
  MI.addOperand(MCOperand::createReg(GPRDecoderTable[Reg1]));
  // Input 0: reg3 (data to store)
  MI.addOperand(MCOperand::createReg(GPRDecoderTable[Reg3]));
  // Input 1: reg1 (base address)
  MI.addOperand(MCOperand::createReg(GPRDecoderTable[Reg1]));

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
  bool HasFPU = STI.hasFeature(V850::FeatureV850FPU);

  // Bit fields used by LDSR/STSR/TRFSR pattern checks below.
  unsigned Opcode6Sysreg = (Insn32 >> 5) & 0x3F; // bits[10:5]
  unsigned RFUSysreg = (Insn32 >> 27) & 0x1F;    // bits[31:27]
  unsigned SubOpSysreg = (Insn32 >> 21) & 0x3F;  // bits[26:21]

  // LDSR/STSR/TRFSR all share opcode=0x3F, RFU=0 and specific SubOp values.
  // These patterns MUST be checked before the auto-generated decoders because:
  //   1. LDHU (opcode=0x3F, FormatVII) is in DecoderTable32 and its 16-bit
  //      displacement field can produce bit patterns identical to LDSR/STSR.
  //   2. TRFSR (FPU) shares its exact encoding with LDSR r0, <sysreg> for
  //      specific register combinations (reg2=0, regID=0).
  // Processing order within this block:
  //   a) TRFSR (when HasFPU): detected by reg2=0, regID=0, bit[20]=0, bit[16]=0
  //   b) LDSR/STSR: all remaining SubOp=100000/100100 patterns
  if (Opcode6Sysreg == 0b111111 && RFUSysreg == 0 &&
      (SubOpSysreg == 0b100000 || SubOpSysreg == 0b100100)) {
    unsigned Reg2 = (Insn32 >> 11) & 0x1F;  // bits[15:11]
    unsigned RegID = Insn32 & 0x1F;         // bits[4:0]
    unsigned SelID = (Insn32 >> 16) & 0x1F; // bits[20:16]

    // Check for TRFSR: LDSR SubOp with reg2=0, regID=0, bit[20]=0, bit[16]=0.
    // These are the conditions that distinguish TRFSR from LDSR r0, <sysreg>
    // for specific (selID even, selID<16) combinations.  When FPU is present,
    // these encodings belong to TRFSR; the fcbit is in bits[19:17].
    if (HasFPU && SubOpSysreg == 0b100000) {
      unsigned Bit20 = (Insn32 >> 20) & 1;
      unsigned Bit16 = (Insn32 >> 16) & 1;
      if (Reg2 == 0 && RegID == 0 && Bit20 == 0 && Bit16 == 0) {
        unsigned FCBit = (Insn32 >> 17) & 0x7;
        MI.clear();
        MI.setOpcode(V850::TRFSR);
        MI.addOperand(MCOperand::createImm(FCBit));
        Size = 4;
        return MCDisassembler::Success;
      }
    }

    // Decode LDSR / STSR using the unified 10-bit sysreg encoding.
    unsigned SysReg = (SelID << 5) | RegID;
    MI.clear();
    if (SubOpSysreg == 0b100000) {
      // LDSR reg2, sysreg
      MI.setOpcode(V850::LDSR);
      if (DecodeGPRRegisterClass(MI, Reg2, Address, this) ==
          MCDisassembler::Fail)
        return MCDisassembler::Fail;
      MI.addOperand(MCOperand::createImm(SysReg));
    } else {
      // STSR sysreg, reg2
      MI.setOpcode(V850::STSR);
      if (DecodeGPRRegisterClass(MI, Reg2, Address, this) ==
          MCDisassembler::Fail)
        return MCDisassembler::Fail;
      MI.addOperand(MCOperand::createImm(SysReg));
    }
    Size = 4;
    return MCDisassembler::Success;
  }

  // Try RH850G4MH-specific instructions (superset of G3M)
  if (STI.hasFeature(V850::FeatureRH850G4MH)) {
    MI.clear();
    DecodeStatus Result = decodeInstruction(DecoderTableRH850G4MH32, MI, Insn32,
                                            Address, this, STI);
    if (Result != MCDisassembler::Fail) {
      Size = 4;
      return Result;
    }
  }

  // Try RH850G3M-specific instructions (superset of V850E2M)
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
  if (Bytes.size() < 6) {
    Size = 0;
    return MCDisassembler::Fail;
  }

  // Read the three 16-bit halfwords in little-endian order.
  uint16_t HW0 = support::endian::read16le(Bytes.data());
  uint16_t HW1 = support::endian::read16le(Bytes.data() + 2);
  uint16_t HW2 = support::endian::read16le(Bytes.data() + 4);

  unsigned Opcode6 = (HW0 >> 5) & 0x3F; // bits[10:5]
  unsigned Reg1No = HW0 & 0x1F;         // bits[4:0]

  bool HasV850E2 = STI.hasFeature(V850::FeatureV850E2);
  bool HasRH850G3M = STI.hasFeature(V850::FeatureRH850G3M);

  // FormatVI_E2: JR32/JARL32 (opcode=0b010111=0x17)
  // Encoding:
  //   HW0: [reg2=0][opcode=0x17][reg1]
  //   HW1: [disp32[15:1]][disp32[0]]
  //   HW2: [disp32[31:16]]
  // JR32: reg1=0, no link; JARL32: reg1=link register
  if (Opcode6 == 0x17 && HasV850E2) {
    // Reconstruct the 32-bit half-displacement from HW1/HW2.
    // HW1 = (disp32[15:1] << 1) | disp32[0], so HW1 = disp32[15:0].
    // HW2 = disp32[31:16].
    uint32_t Disp32 = ((uint32_t)HW2 << 16) | (uint32_t)HW1;
    // Actual byte offset = Disp32 << 1 (all targets are 2-byte aligned).
    int32_t Offset = (int32_t)(Disp32 << 1);

    MI.clear();
    if (Reg1No == 0) {
      // JR32: unconditional jump, no link
      MI.setOpcode(V850::JR32);
      MI.addOperand(MCOperand::createImm(Offset));
    } else {
      // JARL32: jump and link; reg1 is the link register (output)
      MI.setOpcode(V850::JARL32);
      if (DecodeGPRRegisterClass(MI, Reg1No, Address, this) ==
          MCDisassembler::Fail)
        return MCDisassembler::Fail;
      MI.addOperand(MCOperand::createImm(Offset));
    }
    Size = 6;
    return MCDisassembler::Success;
  }

  // FormatVI_E2: JMP32 (opcode=0b110111=0x37, bit[16]=0)
  // LOOP (32-bit) uses the same opcode but has bit[16]=1 (hardcoded).
  // JMP32 has bit[16] = disp32[0] = 0 because all valid targets are
  // 2-byte aligned (even addresses).
  if (Opcode6 == 0x37 && HasV850E2 && (HW1 & 1) == 0) {
    uint32_t Disp32 = ((uint32_t)HW2 << 16) | (uint32_t)HW1;
    int32_t Offset = (int32_t)(Disp32 << 1);

    MI.clear();
    MI.setOpcode(V850::JMP32);
    // reg1 is the base address register (input)
    if (DecodeGPRRegisterClass(MI, Reg1No, Address, this) ==
        MCDisassembler::Fail)
      return MCDisassembler::Fail;
    MI.addOperand(MCOperand::createImm(Offset));
    Size = 6;
    return MCDisassembler::Success;
  }

  // Format XIV: LD.DW / ST.DW (opcode=0b111101=0x3D, RH850G3M+)
  // Encoding:
  //   HW0: [reg2=0][opcode=0x3D][reg1]
  //   HW1: [reg3][disp23[6:1]][sub-opcode]
  //   HW2: [disp23[22:7]]
  // sub-opcode 0b01001 (9) = LD.DW, 0b01111 (15) = ST.DW
  if (Opcode6 == 0x3D && HasRH850G3M) {
    // HW1 bit fields (which form Inst[31:16]):
    //   Inst[31:27] = reg3   → HW1 bits[15:11]
    //   Inst[26:21] = disp23[6:1] → HW1 bits[10:5]
    //   Inst[20:16] = sub-opcode  → HW1 bits[4:0]
    unsigned Reg3No = (HW1 >> 11) & 0x1F;
    unsigned Disp6_1 = (HW1 >> 5) & 0x3F;
    unsigned SubOp = HW1 & 0x1F;

    // Reconstruct disp23:
    //   disp23[0]   = 0 (always 0; all loads/stores are 2-byte aligned)
    //   disp23[6:1] = Disp6_1
    //   disp23[22:7] = HW2
    // Raw 23-bit value: (HW2 << 7) | (Disp6_1 << 1)
    uint32_t Disp23Raw = ((uint32_t)HW2 << 7) | ((uint32_t)Disp6_1 << 1);
    int32_t Disp23 = SignExtend32<23>(Disp23Raw);

    if (SubOp == 0b01001) {
      // LD.DW disp23[reg1], reg3
      // Operands: [reg3 (out), reg1 (in), disp23 (in)]
      MI.clear();
      MI.setOpcode(V850::LD_DW);
      if (DecodeGPRRegisterClass(MI, Reg3No, Address, this) ==
          MCDisassembler::Fail)
        return MCDisassembler::Fail;
      if (DecodeGPRRegisterClass(MI, Reg1No, Address, this) ==
          MCDisassembler::Fail)
        return MCDisassembler::Fail;
      MI.addOperand(MCOperand::createImm(Disp23));
      Size = 6;
      return MCDisassembler::Success;
    }

    if (SubOp == 0b01111) {
      // ST.DW reg3, disp23[reg1]
      // Operands: [reg3 (in), reg1 (in), disp23 (in)]
      MI.clear();
      MI.setOpcode(V850::ST_DW);
      if (DecodeGPRRegisterClass(MI, Reg3No, Address, this) ==
          MCDisassembler::Fail)
        return MCDisassembler::Fail;
      if (DecodeGPRRegisterClass(MI, Reg1No, Address, this) ==
          MCDisassembler::Fail)
        return MCDisassembler::Fail;
      MI.addOperand(MCOperand::createImm(Disp23));
      Size = 6;
      return MCDisassembler::Success;
    }

    // Unknown sub-opcode for 0x3D.
    return MCDisassembler::Fail;
  }

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

  // Check for additional 48-bit instructions (V850E2+ and RH850G3M+).
  //
  // JR32/JARL32: opcode=0x17 (0b010111), reg2=0, V850E2+
  //   Same opcode as 16-bit SATADD-imm form, distinguished by reg2=0.
  if (Opcode6 == 0x17 && Reg2 == 0 && STI.hasFeature(V850::FeatureV850E2) &&
      Bytes.size() >= 6) {
    MI.clear();
    DecodeStatus R = getInstruction48(MI, Size, Bytes, Address, CS);
    if (R != MCDisassembler::Fail)
      return R;
  }

  // JMP32: opcode=0x37 (0b110111), reg2=0, bit[16]=0, V850E2+
  //   LOOP (32-bit G3M) uses same opcode but with bit[16]=1 (hardcoded).
  //   bit[16] is the LSB of the second halfword; 0 means even displacement
  //   (required for 2-byte aligned branch targets).
  if (Opcode6 == 0x37 && Reg2 == 0 && STI.hasFeature(V850::FeatureV850E2) &&
      Bytes.size() >= 6) {
    uint16_t SecondHW = support::endian::read16le(Bytes.data() + 2);
    if ((SecondHW & 1) == 0) {
      MI.clear();
      DecodeStatus R = getInstruction48(MI, Size, Bytes, Address, CS);
      if (R != MCDisassembler::Fail)
        return R;
    }
    // If bit[16]=1, fall through to 32-bit decoder for LOOP.
  }

  // LD.DW / ST.DW: opcode=0x3D (0b111101), RH850G3M+
  if (Opcode6 == 0x3D && STI.hasFeature(V850::FeatureRH850G3M) &&
      Bytes.size() >= 6) {
    MI.clear();
    DecodeStatus R = getInstruction48(MI, Size, Bytes, Address, CS);
    if (R != MCDisassembler::Fail)
      return R;
  }

  // Decide whether to try 16-bit or 32-bit first using a small heuristic.
  // Many 32-bit V850 formats use the extended opcode value 0b111111 in
  // bits [10:5] of the first halfword (FormatIX/XI/XII/etc.). If those
  // bits are 0b111111, prefer the 32-bit decoder first.
  //
  // Also, Format V (JR/JARL) has opcode 0b101111 in bits [10:5]. The first
  // halfword happens to match Format III (Bcond) pattern because bits[10:7]
  // equals 0b1011 (branch opcode), so we need to prefer 32-bit for Format V.

  unsigned Opcode5 = (Insn16 >> 6) & 0x1F; // bits[10:6]
  bool Prefer32 =
      (Opcode6 == 0x3F) ||            // Extended opcode
      (Opcode6 == 0x2F) ||            // JR/JARL (Format V)
      (Reg2 == 0 && Opcode5 == 0x19); // PREPARE/DISPOSE (FormatXIII)

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
