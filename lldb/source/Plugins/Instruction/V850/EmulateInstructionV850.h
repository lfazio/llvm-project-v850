//===-- EmulateInstructionV850.h --------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLDB_SOURCE_PLUGINS_INSTRUCTION_V850_EMULATEINSTRUCTIONV850_H
#define LLDB_SOURCE_PLUGINS_INSTRUCTION_V850_EMULATEINSTRUCTIONV850_H

#include "lldb/Core/EmulateInstruction.h"
#include "lldb/Interpreter/OptionValue.h"
#include "lldb/Utility/Log.h"
#include <optional>

namespace lldb_private {

class EmulateInstructionV850 : public EmulateInstruction {
public:
  EmulateInstructionV850(const ArchSpec &arch);

  static void Initialize();
  static void Terminate();

  static llvm::StringRef GetPluginNameStatic() { return "v850"; }
  static llvm::StringRef GetPluginDescriptionStatic();

  static EmulateInstruction *CreateInstance(const ArchSpec &arch,
                                            InstructionType inst_type);

  static bool
  SupportsEmulatingInstructionsOfTypeStatic(InstructionType inst_type) {
    switch (inst_type) {
    case eInstructionTypeAny:
    case eInstructionTypePrologueEpilogue:
      return true;
    case eInstructionTypePCModifying:
    case eInstructionTypeAll:
      return false;
    }
    return false;
  }

  llvm::StringRef GetPluginName() override { return GetPluginNameStatic(); }

  bool SetTargetTriple(const ArchSpec &arch) override;

  bool SupportsEmulatingInstructionsOfType(InstructionType inst_type) override {
    return SupportsEmulatingInstructionsOfTypeStatic(inst_type);
  }

  bool ReadInstruction() override;
  bool EvaluateInstruction(uint32_t evaluate_options) override;

  bool TestEmulation(Stream &out_stream, ArchSpec &arch,
                     OptionValueDictionary *test_data) override {
    return false;
  }

  std::optional<RegisterInfo> GetRegisterInfo(lldb::RegisterKind reg_kind,
                                              uint32_t reg_num) override;

  bool CreateFunctionEntryUnwind(UnwindPlan &unwind_plan) override;

private:
  // V850 DWARF register numbers
  enum {
    dwarf_r0 = 0,
    dwarf_r1,
    dwarf_r2,
    dwarf_sp, // r3
    dwarf_gp, // r4
    dwarf_tp, // r5
    dwarf_r6,
    dwarf_r7,
    dwarf_r8,
    dwarf_r9,
    dwarf_r10,
    dwarf_r11,
    dwarf_r12,
    dwarf_r13,
    dwarf_r14,
    dwarf_r15,
    dwarf_r16,
    dwarf_r17,
    dwarf_r18,
    dwarf_r19,
    dwarf_r20,
    dwarf_r21,
    dwarf_r22,
    dwarf_r23,
    dwarf_r24,
    dwarf_r25,
    dwarf_r26,
    dwarf_r27,
    dwarf_r28,
    dwarf_fp, // r29
    dwarf_ep, // r30
    dwarf_lp, // r31
    dwarf_pc = 64,
    dwarf_psw = 65
  };

  struct Opcode {
    uint32_t mask;
    uint32_t value;
    bool (EmulateInstructionV850::*callback)(uint32_t opcode);
    const char *name;
  };

  uint32_t m_fp = LLDB_INVALID_REGNUM;

  Opcode *GetOpcodeForInstruction(uint32_t opcode);

  // Instruction emulation methods
  bool EmulatePREPARE(uint32_t opcode);
  bool EmulateDISPOSE(uint32_t opcode);
  bool EmulateADD_SP(uint32_t opcode);
  bool EmulateADDI_SP(uint32_t opcode);
  bool EmulateSTW(uint32_t opcode);
  bool EmulateLDW(uint32_t opcode);
  bool EmulateMOV_FP(uint32_t opcode);

  // Helper to get register name for logging
  const char *GetRegisterName(uint32_t reg_num);
};

} // namespace lldb_private

#endif // LLDB_SOURCE_PLUGINS_INSTRUCTION_V850_EMULATEINSTRUCTIONV850_H
