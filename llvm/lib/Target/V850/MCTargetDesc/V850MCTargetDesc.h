//===-- V850MCTargetDesc.h - V850 Target Descriptions -----------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file provides V850 specific target descriptions.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V850_MCTARGETDESC_V850MCTARGETDESC_H
#define LLVM_LIB_TARGET_V850_MCTARGETDESC_V850MCTARGETDESC_H

#include "llvm/MC/MCFixup.h"
#include "llvm/MC/MCTargetOptions.h"
#include "llvm/Support/DataTypes.h"
#include <memory>

namespace llvm {

namespace V850 {
/// Fixup kinds for V850 backend
enum Fixups {
  /// 9-bit PC-relative branch (Format III conditional branches)
  fixup_v850_9_pcrel = FirstTargetFixupKind,
  /// 22-bit PC-relative branch (Format V: JR, JARL)
  fixup_v850_22_pcrel,
  /// 16-bit signed immediate (Format VI/VII)
  fixup_v850_16,
  /// 32-bit absolute address
  fixup_v850_32,
  /// High 16 bits for MOVHI
  fixup_v850_hi16,
  /// Low 16 bits for MOVEA/ADDI
  fixup_v850_lo16,
  /// GP-relative 16-bit offset for small data area (SDA)
  fixup_v850_sda_16,

  // Marker for last fixup kind
  fixup_v850_invalid,
  NumTargetFixupKinds = fixup_v850_invalid - FirstTargetFixupKind
};
} // namespace V850
class MCAsmBackend;
class MCCodeEmitter;
class MCContext;
class MCInstrInfo;
class MCObjectTargetWriter;
class MCRegisterInfo;
class MCSubtargetInfo;
class Target;

MCCodeEmitter *createV850MCCodeEmitter(MCInstrInfo const &MCII, MCContext &Ctx);

MCAsmBackend *createV850AsmBackend(const Target &T, const MCSubtargetInfo &STI,
                                   const MCRegisterInfo &MRI,
                                   const MCTargetOptions &Options);

std::unique_ptr<MCObjectTargetWriter> createV850ELFObjectWriter(uint8_t OSABI);

} // namespace llvm

// Defines symbolic names for V850 registers.
// This defines a mapping from register name to register number.
#define GET_REGINFO_ENUM
#include "V850GenRegisterInfo.inc"

// Defines symbolic names for V850 instructions.
#define GET_INSTRINFO_ENUM
#define GET_INSTRINFO_MC_HELPER_DECLS
#include "V850GenInstrInfo.inc"

#define GET_SUBTARGETINFO_ENUM
#include "V850GenSubtargetInfo.inc"

#endif // LLVM_LIB_TARGET_V850_MCTARGETDESC_V850MCTARGETDESC_H
