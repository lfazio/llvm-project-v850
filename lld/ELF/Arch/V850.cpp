//===- V850.cpp -----------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// V850 is a 32-bit RISC microcontroller architecture from NEC/Renesas.
// It features:
// - 32 general-purpose registers (r0-r31)
// - Special pointer registers: SP (r3), GP (r4), TP (r5), EP (r30), LP (r31)
// - Small data areas: SDA (GP-relative), TDA (EP-relative), ZDA (zero-page)
// - 16/32/48-bit instruction encoding
// - Little-endian byte ordering
//
//===----------------------------------------------------------------------===//

#include "Symbols.h"
#include "Target.h"
#include "llvm/BinaryFormat/ELF.h"
#include "llvm/Support/Endian.h"

using namespace llvm;
using namespace llvm::object;
using namespace llvm::support::endian;
using namespace llvm::ELF;
using namespace lld;
using namespace lld::elf;

namespace {
class V850 final : public TargetInfo {
public:
  V850(Ctx &ctx);
  RelExpr getRelExpr(RelType type, const Symbol &s,
                     const uint8_t *loc) const override;
  void relocate(uint8_t *loc, const Relocation &rel,
                uint64_t val) const override;
};
} // namespace

V850::V850(Ctx &ctx) : TargetInfo(ctx) {
  // V850 NOP: mov r0, r0 = 0x0000
  trapInstr = {0x00, 0x00, 0x00, 0x00};

  // Default page size (no MMU on most V850)
  defaultMaxPageSize = 4;
  defaultCommonPageSize = 4;
}

RelExpr V850::getRelExpr(RelType type, const Symbol &s,
                         const uint8_t *loc) const {
  switch (type) {
  case R_V850_9_PCREL:
  case R_V850_22_PCREL:
    return R_PC;
  case R_V850_SDA_16_16_OFFSET:
  case R_V850_SDA_15_16_OFFSET:
    // GP-relative addressing - treat as GOT-relative for now
    return R_GOTREL;
  case R_V850_TDA_6_8_OFFSET:
  case R_V850_TDA_7_8_OFFSET:
  case R_V850_TDA_7_7_OFFSET:
  case R_V850_TDA_16_16_OFFSET:
    // EP-relative addressing - treat as GOT-relative for now
    return R_GOTREL;
  case R_V850_ZDA_16_16_OFFSET:
  case R_V850_ZDA_15_16_OFFSET:
    // Zero-page relative (absolute low address)
    return R_ABS;
  default:
    return R_ABS;
  }
}

void V850::relocate(uint8_t *loc, const Relocation &rel, uint64_t val) const {
  switch (rel.type) {
  case R_V850_NONE:
    break;

  case R_V850_8:
    checkIntUInt(ctx, loc, val, 8, rel);
    *loc = val;
    break;

  case R_V850_16:
    checkIntUInt(ctx, loc, val, 16, rel);
    write16le(loc, val);
    break;

  case R_V850_32:
    write32le(loc, val);
    break;

  case R_V850_9_PCREL: {
    // 9-bit PC-relative displacement, shifted right by 1 (halfword aligned)
    // Format III conditional branch: Bcond disp9
    // Encoding: bits [15:11] = disp[8:4], bits [6:4] = disp[3:1]
    int64_t offset = static_cast<int64_t>(val);
    checkInt(ctx, loc, offset, 9, rel);
    // V850 branches use halfword units
    int64_t hwOffset = offset >> 1;
    uint16_t insn = read16le(loc);
    // Clear displacement bits and insert new value
    insn = (insn & 0x078F) | ((hwOffset & 0x07) << 4) |
           ((hwOffset & 0xF8) << 8);
    write16le(loc, insn);
    break;
  }

  case R_V850_22_PCREL: {
    // 22-bit PC-relative displacement, shifted right by 1 (halfword aligned)
    // Format V: JR/JARL disp22
    // 32-bit instruction with displacement split across both halfwords
    int64_t offset = static_cast<int64_t>(val);
    checkInt(ctx, loc, offset, 22, rel);
    int64_t hwOffset = offset >> 1;
    // First halfword: bits [5:0] = disp[5:0], bits [15:6] = opcode
    // Second halfword: bits [15:0] = disp[21:6]
    uint16_t lo = read16le(loc);
    lo = (lo & 0xFFC0) | (hwOffset & 0x3F);
    write16le(loc, lo);
    write16le(loc + 2, (hwOffset >> 6) & 0xFFFF);
    break;
  }

  case R_V850_HI16: {
    // Upper 16 bits of 32-bit address
    // Used with MOVHI instruction - immediate is in second halfword
    // Handle sign-extension adjustment: if lo16 is negative, increment hi16
    uint32_t hi = ((val + 0x8000) >> 16) & 0xFFFF;
    write16le(loc + 2, hi);
    break;
  }

  case R_V850_LO16: {
    // Lower 16 bits of 32-bit address
    // Used with MOVEA/ADDI instruction - immediate is in second halfword
    uint16_t lo = val & 0xFFFF;
    write16le(loc + 2, lo);
    break;
  }

  case R_V850_SDA_16_16_OFFSET:
  case R_V850_ZDA_16_16_OFFSET:
    // 16-bit signed offset in second halfword of 32-bit instruction
    checkInt(ctx, loc, val, 16, rel);
    write16le(loc + 2, val & 0xFFFF);
    break;

  case R_V850_SDA_15_16_OFFSET:
  case R_V850_ZDA_15_16_OFFSET:
    // 15-bit signed offset (shifted left by 1 for halfword access)
    checkInt(ctx, loc, static_cast<int64_t>(val) >> 1, 15, rel);
    write16le(loc + 2, val & 0xFFFE);
    break;

  case R_V850_TDA_6_8_OFFSET:
    // 6-bit unsigned offset for byte access via EP
    // Stored in bits [6:1] of first byte
    checkUInt(ctx, loc, val, 7, rel);
    loc[0] = (loc[0] & 0x81) | ((val & 0x7E));
    break;

  case R_V850_TDA_7_8_OFFSET:
    // 7-bit unsigned offset for halfword access via EP
    // Stored shifted left by 1
    checkUInt(ctx, loc, val >> 1, 7, rel);
    loc[0] = (loc[0] & 0x80) | ((val >> 1) & 0x7F);
    break;

  case R_V850_TDA_7_7_OFFSET:
    // 7-bit unsigned offset (direct)
    checkUInt(ctx, loc, val, 7, rel);
    loc[0] = (loc[0] & 0x80) | (val & 0x7F);
    break;

  case R_V850_TDA_16_16_OFFSET:
    // 16-bit offset for word access via EP
    checkInt(ctx, loc, val, 16, rel);
    write16le(loc + 2, val & 0xFFFF);
    break;

  default:
    Err(ctx) << getErrorLoc(ctx, loc) << "unrecognized relocation " << rel.type;
  }
}

void elf::setV850TargetInfo(Ctx &ctx) { ctx.target.reset(new V850(ctx)); }
