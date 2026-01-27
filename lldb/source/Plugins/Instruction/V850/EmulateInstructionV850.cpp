//===-- EmulateInstructionV850.cpp ----------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "EmulateInstructionV850.h"

#include <cstdlib>
#include <optional>

#include "lldb/Core/PluginManager.h"
#include "lldb/Symbol/UnwindPlan.h"
#include "lldb/Utility/ArchSpec.h"
#include "lldb/Utility/ConstString.h"
#include "lldb/Utility/LLDBLog.h"

using namespace lldb;
using namespace lldb_private;

LLDB_PLUGIN_DEFINE_ADV(EmulateInstructionV850, InstructionV850)

// V850 Register Info table
static const RegisterInfo g_register_infos_v850[] = {
    {"r0",
     "zero",
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {0, 0, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r1",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {1, 1, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r2",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {2, 2, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r3",
     "sp",
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {3, 3, LLDB_REGNUM_GENERIC_SP, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r4",
     "gp",
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {4, 4, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r5",
     "tp",
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {5, 5, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r6",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {6, 6, LLDB_REGNUM_GENERIC_ARG1, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r7",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {7, 7, LLDB_REGNUM_GENERIC_ARG2, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r8",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {8, 8, LLDB_REGNUM_GENERIC_ARG3, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r9",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {9, 9, LLDB_REGNUM_GENERIC_ARG4, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r10",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {10, 10, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r11",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {11, 11, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r12",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {12, 12, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r13",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {13, 13, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r14",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {14, 14, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r15",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {15, 15, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r16",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {16, 16, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r17",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {17, 17, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r18",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {18, 18, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r19",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {19, 19, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r20",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {20, 20, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r21",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {21, 21, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r22",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {22, 22, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r23",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {23, 23, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r24",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {24, 24, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r25",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {25, 25, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r26",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {26, 26, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r27",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {27, 27, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r28",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {28, 28, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r29",
     "fp",
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {29, 29, LLDB_REGNUM_GENERIC_FP, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r30",
     "ep",
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {30, 30, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"r31",
     "lp",
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {31, 31, LLDB_REGNUM_GENERIC_RA, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"pc",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {64, 64, LLDB_REGNUM_GENERIC_PC, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
    {"psw",
     nullptr,
     4,
     0,
     eEncodingUint,
     eFormatHex,
     {65, 65, LLDB_REGNUM_GENERIC_FLAGS, LLDB_INVALID_REGNUM,
      LLDB_INVALID_REGNUM},
     nullptr,
     nullptr,
     nullptr},
};

static std::optional<RegisterInfo> LLDBTableGetRegisterInfo(uint32_t reg_num) {
  if (reg_num >= std::size(g_register_infos_v850))
    return {};
  return g_register_infos_v850[reg_num];
}

EmulateInstructionV850::EmulateInstructionV850(const ArchSpec &arch)
    : EmulateInstruction(arch) {}

void EmulateInstructionV850::Initialize() {
  PluginManager::RegisterPlugin(GetPluginNameStatic(),
                                GetPluginDescriptionStatic(), CreateInstance);
}

void EmulateInstructionV850::Terminate() {
  PluginManager::UnregisterPlugin(CreateInstance);
}

llvm::StringRef EmulateInstructionV850::GetPluginDescriptionStatic() {
  return "Emulate instructions for the V850 architecture.";
}

EmulateInstruction *
EmulateInstructionV850::CreateInstance(const ArchSpec &arch,
                                       InstructionType inst_type) {
  if (SupportsEmulatingInstructionsOfTypeStatic(inst_type))
    if (arch.GetTriple().getArch() == llvm::Triple::v850)
      return new EmulateInstructionV850(arch);

  return nullptr;
}

bool EmulateInstructionV850::SetTargetTriple(const ArchSpec &arch) {
  return arch.GetTriple().getArch() == llvm::Triple::v850;
}

std::optional<RegisterInfo>
EmulateInstructionV850::GetRegisterInfo(RegisterKind reg_kind,
                                        uint32_t reg_num) {
  if (reg_kind == eRegisterKindGeneric) {
    switch (reg_num) {
    case LLDB_REGNUM_GENERIC_PC:
      reg_kind = eRegisterKindLLDB;
      reg_num = dwarf_pc;
      break;
    case LLDB_REGNUM_GENERIC_SP:
      reg_kind = eRegisterKindLLDB;
      reg_num = dwarf_sp;
      break;
    case LLDB_REGNUM_GENERIC_FP:
      reg_kind = eRegisterKindLLDB;
      reg_num = dwarf_fp;
      break;
    case LLDB_REGNUM_GENERIC_RA:
      reg_kind = eRegisterKindLLDB;
      reg_num = dwarf_lp;
      break;
    case LLDB_REGNUM_GENERIC_FLAGS:
      reg_kind = eRegisterKindLLDB;
      reg_num = dwarf_psw;
      break;
    default:
      return {};
    }
  }

  if (reg_kind == eRegisterKindDWARF || reg_kind == eRegisterKindLLDB)
    return LLDBTableGetRegisterInfo(reg_num);
  return {};
}

bool EmulateInstructionV850::ReadInstruction() {
  bool success = false;
  m_addr = ReadRegisterUnsigned(eRegisterKindGeneric, LLDB_REGNUM_GENERIC_PC,
                                LLDB_INVALID_ADDRESS, &success);
  if (!success)
    return false;

  Context ctx;
  ctx.type = eContextReadOpcode;
  ctx.SetNoArgs();

  // V850 instructions can be 16-bit or 32-bit.
  // Read 16 bits first to determine instruction length.
  uint16_t first_halfword =
      (uint16_t)ReadMemoryUnsigned(ctx, m_addr, 2, 0, &success);
  if (!success) {
    m_addr = LLDB_INVALID_ADDRESS;
    return false;
  }

  // Check if this is a 32-bit instruction by looking at the opcode pattern.
  // 32-bit instructions have specific patterns in their first halfword.
  // Format V (JR/JARL), Format VI (3-reg), Format VII (ld/st base+reg),
  // Format VIII (bit), Format IX (ext 2-reg), Format X (ext 1-reg),
  // Format XI (ext 3-reg), Format XII (ext imm), Format XIII (PREPARE/DISPOSE)
  // are all 32-bit.

  // Check for common 32-bit instruction patterns:
  // - PREPARE/DISPOSE: opcode[15:11] = 11110 (0x1E << 11 = 0xF000)
  // - Format VI/VII/IX/X/XI (extended): opcode[10:5] indicates extended format
  uint8_t op_high = (first_halfword >> 11) & 0x1F;
  uint8_t op_mid = (first_halfword >> 5) & 0x3F;

  bool is_32bit = false;
  if (op_high == 0x1F) {
    // Potential 32-bit: check further
    // Format XIII (PREPARE/DISPOSE): 0000011110iiiiil llllLLLLLLLLL001
    // First halfword: 0x0780 - 0x07BF for PREPARE, 0x0640 - 0x067F for DISPOSE
    is_32bit = true;
  } else if (op_high == 0x17 || op_high == 0x1E) {
    // Format V (JR/JARL) or Format XIII
    is_32bit = true;
  } else if ((first_halfword & 0xFC00) == 0x7800 ||
             (first_halfword & 0xFC00) == 0x7C00) {
    // Format IX/X extended instructions
    is_32bit = true;
  } else if ((first_halfword & 0x0600) == 0x0600 && op_mid >= 0x30) {
    // Various 32-bit formats
    is_32bit = true;
  }

  // Check specifically for PREPARE (0111100) and DISPOSE (0110010)
  // PREPARE: 0000011110iiiii0 llllLLLLLLLLLff1
  // DISPOSE: 0000011001iiiiii llllLLLLLLLLLff0 (without reg) or ff1 (with reg)
  uint8_t opcode_6_10 = (first_halfword >> 5) & 0x3F;
  if (opcode_6_10 == 0x1E || opcode_6_10 == 0x19) {
    // PREPARE or DISPOSE
    is_32bit = true;
  }

  if (is_32bit) {
    // Read second halfword
    uint16_t second_halfword =
        (uint16_t)ReadMemoryUnsigned(ctx, m_addr + 2, 2, 0, &success);
    if (!success) {
      m_addr = LLDB_INVALID_ADDRESS;
      return false;
    }
    // V850 stores instructions in little-endian: second halfword is high part
    uint32_t full_opcode =
        ((uint32_t)second_halfword << 16) | (uint32_t)first_halfword;
    m_opcode.SetOpcode32(full_opcode, GetByteOrder());
  } else {
    m_opcode.SetOpcode16(first_halfword, GetByteOrder());
  }

  return true;
}

bool EmulateInstructionV850::CreateFunctionEntryUnwind(
    UnwindPlan &unwind_plan) {
  unwind_plan.Clear();
  unwind_plan.SetRegisterKind(eRegisterKindDWARF);

  UnwindPlan::Row row;

  // At function entry, CFA = SP
  row.GetCFAValue().SetIsRegisterPlusOffset(dwarf_sp, 0);

  // Return address is in LP (r31)
  row.SetRegisterLocationToRegister(dwarf_pc, dwarf_lp, true);

  unwind_plan.AppendRow(std::move(row));
  unwind_plan.SetSourceName("EmulateInstructionV850");
  unwind_plan.SetSourcedFromCompiler(eLazyBoolNo);
  unwind_plan.SetUnwindPlanValidAtAllInstructions(eLazyBoolYes);
  unwind_plan.SetUnwindPlanForSignalTrap(eLazyBoolNo);
  unwind_plan.SetReturnAddressRegister(dwarf_lp);
  return true;
}

const char *EmulateInstructionV850::GetRegisterName(uint32_t reg_num) {
  if (reg_num < std::size(g_register_infos_v850))
    return g_register_infos_v850[reg_num].name;
  return "?";
}

// Helper function to extract bits from an instruction
static inline uint32_t Bits32(uint32_t bits, uint32_t msbit, uint32_t lsbit) {
  return (bits >> lsbit) & ((1u << (msbit - lsbit + 1)) - 1);
}

EmulateInstructionV850::Opcode *
EmulateInstructionV850::GetOpcodeForInstruction(uint32_t opcode) {
  // V850 opcode table for prologue/epilogue instructions
  static EmulateInstructionV850::Opcode g_opcodes[] = {
      // PREPARE list12, imm5: Format XIII
      // Encoding: 0000011110iiiii0 llllLLLLLLLLLff1
      // Where: iiiii = imm5, l/L = list12, ff = function (00 = no reg, 01 = sp)
      {0x07E1, 0x0780, &EmulateInstructionV850::EmulatePREPARE,
       "prepare list12, imm5"},

      // DISPOSE imm5, list12: Format XIII
      // Encoding: 0000011001iiiiii llllLLLLLLLLLff0/1
      {0x07E0, 0x0640, &EmulateInstructionV850::EmulateDISPOSE,
       "dispose imm5, list12"},

      // ADD imm5, SP (r3): opcode = 0010010011 (add imm5, r3)
      // Format II: rrrrr010011iiiii where rrrrr = 00011 (r3), iiiii = imm5
      {0xFFE0, 0x1A60, &EmulateInstructionV850::EmulateADD_SP, "add imm5, sp"},

      // ADDI imm16, SP, SP: addi imm16, r3, r3
      // Format VI: rrrrr110000RRRRR iiiiiiiiiiiiiiii
      // With RRRRR = 00011 (SP) and rrrrr = 00011 (SP)
      {0xFFE0FFFF, 0x18600600, &EmulateInstructionV850::EmulateADDI_SP,
       "addi imm16, sp, sp"},

      // ST.W reg, disp[SP]: st.w reg, disp16[r3]
      // Format VII: rrrrr111010RRRRR dddddddddddddddd
      // With RRRRR = 00011 (SP)
      {0x07E0, 0x0760, &EmulateInstructionV850::EmulateSTW,
       "st.w reg, disp[sp]"},

      // LD.W disp[SP], reg: ld.w disp16[r3], reg
      // Format VII: rrrrr111001RRRRR dddddddddddddddd
      // With RRRRR = 00011 (SP)
      {0x07E0, 0x0720, &EmulateInstructionV850::EmulateLDW,
       "ld.w disp[sp], reg"},

      // MOV SP, FP: mov r3, r29
      // Format I: rrrrr000000RRRRR where RRRRR = src (r3), rrrrr = dst (r29)
      {0xFFFF, 0xE803, &EmulateInstructionV850::EmulateMOV_FP, "mov sp, fp"},
  };
  static const size_t k_num_opcodes = std::size(g_opcodes);

  for (size_t i = 0; i < k_num_opcodes; ++i) {
    if ((g_opcodes[i].mask & opcode) == g_opcodes[i].value)
      return &g_opcodes[i];
  }
  return nullptr;
}

bool EmulateInstructionV850::EvaluateInstruction(uint32_t evaluate_options) {
  uint32_t opcode = m_opcode.GetOpcode32();
  Opcode *opcode_data = GetOpcodeForInstruction(opcode);
  if (!opcode_data)
    return false;

  Log *log = GetLog(LLDBLog::Unwind);
  LLDB_LOG(log, "V850::EvaluateInstruction: {0:X+8}: {1}", m_addr,
           opcode_data->name);

  const bool auto_advance_pc =
      evaluate_options & eEmulateInstructionOptionAutoAdvancePC;

  bool success = false;
  uint32_t orig_pc_value = 0;
  if (auto_advance_pc) {
    orig_pc_value =
        ReadRegisterUnsigned(eRegisterKindDWARF, dwarf_pc, 0, &success);
    if (!success)
      return false;
  }

  // Call the emulation function
  success = (this->*opcode_data->callback)(opcode);
  if (!success)
    return false;

  if (auto_advance_pc) {
    uint32_t new_pc_value =
        ReadRegisterUnsigned(eRegisterKindDWARF, dwarf_pc, 0, &success);
    if (!success)
      return false;

    if (new_pc_value == orig_pc_value) {
      EmulateInstruction::Context context;
      context.type = eContextAdvancePC;
      context.SetNoArgs();
      // Advance by instruction size (16-bit or 32-bit)
      uint32_t inst_size = m_opcode.GetByteSize();
      if (!WriteRegisterUnsigned(context, eRegisterKindDWARF, dwarf_pc,
                                 orig_pc_value + inst_size))
        return false;
    }
  }
  return true;
}

// PREPARE list12, imm5
// Saves callee-saved registers and allocates stack space.
// Register save order: LP (r31), EP (r30), r29, r28, ..., r20
bool EmulateInstructionV850::EmulatePREPARE(uint32_t opcode) {
  Log *log = GetLog(LLDBLog::Unwind);

  // Extract fields from PREPARE instruction
  // Format: [31:16] = second halfword, [15:0] = first halfword
  // list12 bits are scattered across the instruction
  uint32_t imm5 = Bits32(opcode, 5, 1);      // imm5 field
  uint32_t list_lo = Bits32(opcode, 31, 21); // list12[11:1]
  uint32_t list_hi = Bits32(opcode, 0, 0);   // list12[0] (LP bit)

  uint32_t list12 = (list_lo << 1) | list_hi;
  uint32_t stack_adjust = imm5 * 4;

  LLDB_LOG(log, "EmulatePREPARE: {0:X+8}: prepare list12={1:X+3}, imm5={2}",
           m_addr, list12, imm5);

  bool success;
  uint64_t sp = ReadRegisterUnsigned(eRegisterKindDWARF, dwarf_sp, 0, &success);
  if (!success)
    return false;

  // PREPARE saves registers in order: LP, EP, r29, r28, ..., r20
  // Each register corresponds to a bit in list12:
  // bit 11 = LP (r31), bit 10 = EP (r30), bit 9 = r29, ..., bit 0 = r20
  static const uint32_t prepare_regs[] = {
      dwarf_lp,  dwarf_ep,  dwarf_fp,  dwarf_r28, dwarf_r27, dwarf_r26,
      dwarf_r25, dwarf_r24, dwarf_r23, dwarf_r22, dwarf_r21, dwarf_r20};

  int32_t offset = 0;
  for (int i = 0; i < 12; ++i) {
    if (list12 & (1 << (11 - i))) {
      uint32_t reg = prepare_regs[i];
      offset -= 4;

      uint64_t reg_val =
          ReadRegisterUnsigned(eRegisterKindDWARF, reg, 0, &success);
      if (!success)
        return false;

      std::optional<RegisterInfo> reg_info =
          GetRegisterInfo(eRegisterKindDWARF, reg);
      if (!reg_info)
        return false;

      std::optional<RegisterInfo> sp_info =
          GetRegisterInfo(eRegisterKindDWARF, dwarf_sp);
      if (!sp_info)
        return false;

      Context ctx;
      ctx.type = eContextPushRegisterOnStack;
      ctx.SetRegisterToRegisterPlusOffset(*reg_info, *sp_info, offset);

      if (!WriteMemory(ctx, sp + offset, &reg_val, sizeof(uint32_t)))
        return false;

      LLDB_LOG(log, "EmulatePREPARE: saved {0} at SP{1}", GetRegisterName(reg),
               offset);
    }
  }

  // Update SP: SP = SP + offset - (imm5 * 4)
  int32_t total_adjust = offset - static_cast<int32_t>(stack_adjust);

  Context ctx;
  ctx.type = eContextAdjustStackPointer;
  std::optional<RegisterInfo> sp_info =
      GetRegisterInfo(eRegisterKindDWARF, dwarf_sp);
  if (sp_info)
    ctx.SetRegisterPlusOffset(*sp_info, total_adjust);

  if (!WriteRegisterUnsigned(ctx, eRegisterKindDWARF, dwarf_sp,
                             sp + total_adjust))
    return false;

  LLDB_LOG(log, "EmulatePREPARE: SP adjusted by {0}, new SP = {1:X+8}",
           total_adjust, sp + total_adjust);

  return true;
}

// DISPOSE imm5, list12
// Deallocates stack space and restores callee-saved registers.
bool EmulateInstructionV850::EmulateDISPOSE(uint32_t opcode) {
  Log *log = GetLog(LLDBLog::Unwind);

  // Extract fields - similar to PREPARE but different encoding
  uint32_t imm5 = Bits32(opcode, 5, 1);
  uint32_t list_lo = Bits32(opcode, 31, 21);
  uint32_t list_hi = Bits32(opcode, 0, 0);

  uint32_t list12 = (list_lo << 1) | list_hi;
  uint32_t stack_adjust = imm5 * 4;

  LLDB_LOG(log, "EmulateDISPOSE: {0:X+8}: dispose imm5={1}, list12={2:X+3}",
           m_addr, imm5, list12);

  bool success;
  uint64_t sp = ReadRegisterUnsigned(eRegisterKindDWARF, dwarf_sp, 0, &success);
  if (!success)
    return false;

  // First, add imm5*4 to SP
  sp += stack_adjust;

  // DISPOSE restores registers in reverse order: r20, r21, ..., r29, EP, LP
  static const uint32_t dispose_regs[] = {
      dwarf_r20, dwarf_r21, dwarf_r22, dwarf_r23, dwarf_r24, dwarf_r25,
      dwarf_r26, dwarf_r27, dwarf_r28, dwarf_fp,  dwarf_ep,  dwarf_lp};

  int32_t offset = 0;
  for (int i = 0; i < 12; ++i) {
    if (list12 & (1 << i)) {
      uint32_t reg = dispose_regs[i];

      uint32_t reg_val = 0;
      Context ctx;
      ctx.type = eContextRegisterLoad;
      ctx.SetNoArgs();

      if (!ReadMemory(ctx, sp + offset, &reg_val, sizeof(uint32_t)))
        return false;

      Context write_ctx;
      write_ctx.type = eContextRestoreStackPointer;
      write_ctx.SetNoArgs();

      if (!WriteRegisterUnsigned(write_ctx, eRegisterKindDWARF, reg, reg_val))
        return false;

      LLDB_LOG(log, "EmulateDISPOSE: restored {0} = {1:X+8} from SP+{2}",
               GetRegisterName(reg), reg_val, offset);

      offset += 4;
    }
  }

  // Update SP
  Context ctx;
  ctx.type = eContextRestoreStackPointer;
  std::optional<RegisterInfo> sp_info =
      GetRegisterInfo(eRegisterKindDWARF, dwarf_sp);
  if (sp_info)
    ctx.SetRegister(*sp_info);

  if (!WriteRegisterUnsigned(ctx, eRegisterKindDWARF, dwarf_sp, sp + offset))
    return false;

  LLDB_LOG(log, "EmulateDISPOSE: new SP = {0:X+8}", sp + offset);

  return true;
}

// ADD imm5, SP: add sign-extended 5-bit immediate to SP
bool EmulateInstructionV850::EmulateADD_SP(uint32_t opcode) {
  Log *log = GetLog(LLDBLog::Unwind);

  // Format II: rrrrr010011iiiii
  int32_t imm5 = llvm::SignExtend32<5>(Bits32(opcode, 4, 0));

  LLDB_LOG(log, "EmulateADD_SP: {0:X+8}: add {1}, sp", m_addr, imm5);

  bool success;
  uint64_t sp = ReadRegisterUnsigned(eRegisterKindDWARF, dwarf_sp, 0, &success);
  if (!success)
    return false;

  std::optional<RegisterInfo> sp_info =
      GetRegisterInfo(eRegisterKindDWARF, dwarf_sp);
  if (!sp_info)
    return false;

  Context ctx;
  ctx.type = eContextAdjustStackPointer;
  ctx.SetRegisterPlusOffset(*sp_info, imm5);

  if (!WriteRegisterUnsigned(ctx, eRegisterKindDWARF, dwarf_sp, sp + imm5))
    return false;

  LLDB_LOG(log, "EmulateADD_SP: SP = {0:X+8}", sp + imm5);

  return true;
}

// ADDI imm16, SP, SP: add 16-bit immediate to SP
bool EmulateInstructionV850::EmulateADDI_SP(uint32_t opcode) {
  Log *log = GetLog(LLDBLog::Unwind);

  // Format VI: rrrrr110000RRRRR iiiiiiiiiiiiiiii
  int32_t imm16 = llvm::SignExtend32<16>(Bits32(opcode, 31, 16));

  LLDB_LOG(log, "EmulateADDI_SP: {0:X+8}: addi {1}, sp, sp", m_addr, imm16);

  bool success;
  uint64_t sp = ReadRegisterUnsigned(eRegisterKindDWARF, dwarf_sp, 0, &success);
  if (!success)
    return false;

  std::optional<RegisterInfo> sp_info =
      GetRegisterInfo(eRegisterKindDWARF, dwarf_sp);
  if (!sp_info)
    return false;

  Context ctx;
  ctx.type = eContextAdjustStackPointer;
  ctx.SetRegisterPlusOffset(*sp_info, imm16);

  if (!WriteRegisterUnsigned(ctx, eRegisterKindDWARF, dwarf_sp, sp + imm16))
    return false;

  LLDB_LOG(log, "EmulateADDI_SP: SP = {0:X+8}", sp + imm16);

  return true;
}

// ST.W reg, disp[SP]: store register to stack
bool EmulateInstructionV850::EmulateSTW(uint32_t opcode) {
  Log *log = GetLog(LLDBLog::Unwind);

  // Format VII: rrrrr111010RRRRR dddddddddddddddd
  uint32_t reg = Bits32(opcode, 15, 11);
  uint32_t base = Bits32(opcode, 4, 0);
  int32_t disp = llvm::SignExtend32<16>(Bits32(opcode, 31, 16));

  // Only track stores to SP-based addresses
  if (base != dwarf_sp)
    return false;

  LLDB_LOG(log, "EmulateSTW: {0:X+8}: st.w {1}, {2}[sp]", m_addr,
           GetRegisterName(reg), disp);

  bool success;
  uint64_t sp = ReadRegisterUnsigned(eRegisterKindDWARF, dwarf_sp, 0, &success);
  if (!success)
    return false;

  uint64_t reg_val = ReadRegisterUnsigned(eRegisterKindDWARF, reg, 0, &success);
  if (!success)
    return false;

  std::optional<RegisterInfo> reg_info =
      GetRegisterInfo(eRegisterKindDWARF, reg);
  std::optional<RegisterInfo> sp_info =
      GetRegisterInfo(eRegisterKindDWARF, dwarf_sp);
  if (!reg_info || !sp_info)
    return false;

  Context ctx;
  ctx.type = eContextPushRegisterOnStack;
  ctx.SetRegisterToRegisterPlusOffset(*reg_info, *sp_info, disp);

  uint32_t val32 = static_cast<uint32_t>(reg_val);
  if (!WriteMemory(ctx, sp + disp, &val32, sizeof(uint32_t)))
    return false;

  LLDB_LOG(log, "EmulateSTW: stored {0} = {1:X+8} at {2:X+8}",
           GetRegisterName(reg), reg_val, sp + disp);

  return true;
}

// LD.W disp[SP], reg: load register from stack
bool EmulateInstructionV850::EmulateLDW(uint32_t opcode) {
  Log *log = GetLog(LLDBLog::Unwind);

  // Format VII: rrrrr111001RRRRR dddddddddddddddd
  uint32_t reg = Bits32(opcode, 15, 11);
  uint32_t base = Bits32(opcode, 4, 0);
  int32_t disp = llvm::SignExtend32<16>(Bits32(opcode, 31, 16));

  // Only track loads from SP-based addresses
  if (base != dwarf_sp)
    return false;

  // Special case: loading into SP is a stack restore
  bool is_sp_restore = (reg == dwarf_sp);

  LLDB_LOG(log, "EmulateLDW: {0:X+8}: ld.w {1}[sp], {2}", m_addr, disp,
           GetRegisterName(reg));

  bool success;
  uint64_t sp = ReadRegisterUnsigned(eRegisterKindDWARF, dwarf_sp, 0, &success);
  if (!success)
    return false;

  Context read_ctx;
  read_ctx.type = eContextRegisterLoad;
  read_ctx.SetNoArgs();

  uint32_t val32 = 0;
  if (!ReadMemory(read_ctx, sp + disp, &val32, sizeof(uint32_t)))
    return false;

  std::optional<RegisterInfo> reg_info =
      GetRegisterInfo(eRegisterKindDWARF, reg);
  if (!reg_info)
    return false;

  Context ctx;
  if (is_sp_restore) {
    ctx.type = eContextRestoreStackPointer;
    ctx.SetRegister(*reg_info);
  } else {
    ctx.type = eContextRegisterLoad;
    ctx.SetRegister(*reg_info);
  }

  if (!WriteRegisterUnsigned(ctx, eRegisterKindDWARF, reg, val32))
    return false;

  LLDB_LOG(log, "EmulateLDW: loaded {0} = {1:X+8} from {2:X+8}",
           GetRegisterName(reg), val32, sp + disp);

  return true;
}

// MOV SP, FP: set up frame pointer
bool EmulateInstructionV850::EmulateMOV_FP(uint32_t opcode) {
  Log *log = GetLog(LLDBLog::Unwind);

  // Already matched: mov r3, r29
  LLDB_LOG(log, "EmulateMOV_FP: {0:X+8}: mov sp, fp", m_addr);

  bool success;
  uint64_t sp = ReadRegisterUnsigned(eRegisterKindDWARF, dwarf_sp, 0, &success);
  if (!success)
    return false;

  std::optional<RegisterInfo> fp_info =
      GetRegisterInfo(eRegisterKindDWARF, dwarf_fp);
  if (!fp_info)
    return false;

  Context ctx;
  ctx.type = eContextSetFramePointer;
  ctx.SetRegister(*fp_info);

  if (!WriteRegisterUnsigned(ctx, eRegisterKindDWARF, dwarf_fp, sp))
    return false;

  m_fp = dwarf_fp;

  LLDB_LOG(log, "EmulateMOV_FP: FP = SP = {0:X+8}", sp);

  return true;
}
