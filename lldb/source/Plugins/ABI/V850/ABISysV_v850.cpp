//===-- ABISysV_v850.cpp ----------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "ABISysV_v850.h"

#include "lldb/Core/Module.h"
#include "lldb/Core/PluginManager.h"
#include "lldb/Core/Value.h"
#include "lldb/Symbol/UnwindPlan.h"
#include "lldb/Target/Process.h"
#include "lldb/Target/RegisterContext.h"
#include "lldb/Target/StackFrame.h"
#include "lldb/Target/Target.h"
#include "lldb/Target/Thread.h"
#include "lldb/Utility/ConstString.h"
#include "lldb/Utility/DataExtractor.h"
#include "lldb/Utility/Log.h"
#include "lldb/Utility/RegisterValue.h"
#include "lldb/ValueObject/ValueObjectConstResult.h"
#include "lldb/ValueObject/ValueObjectMemory.h"
#include "lldb/ValueObject/ValueObjectRegister.h"

#include "llvm/IR/DerivedTypes.h"
#include "llvm/TargetParser/Triple.h"

#include <optional>

using namespace lldb;
using namespace lldb_private;

LLDB_PLUGIN_DEFINE_ADV(ABISysV_v850, ABIV850)

// V850 DWARF Register Numbers:
//   r0-r31:  0-31 (general purpose registers)
//   PC:      64   (program counter)
//   PSW:     65   (program status word)
//
// V850 Calling Convention:
//   r0:      Zero register (always 0)
//   r3 (SP): Stack pointer
//   r4 (GP): Global pointer
//   r5 (TP): Text pointer
//   r6-r9:   Argument registers (caller-saved)
//   r10-r11: Return value registers
//   r10-r19: Caller-saved temporaries
//   r20-r29: Callee-saved registers
//   r29:     Frame pointer (when used)
//   r30 (EP): Element pointer
//   r31 (LP): Link pointer (return address)

enum dwarf_regnums {
  // General purpose registers
  dwarf_r0 = 0,
  dwarf_r1,
  dwarf_r2,
  dwarf_sp, // r3
  dwarf_gp, // r4
  dwarf_tp, // r5
  dwarf_r6, // First argument
  dwarf_r7,
  dwarf_r8,
  dwarf_r9,  // Last argument
  dwarf_r10, // Return value
  dwarf_r11,
  dwarf_r12,
  dwarf_r13,
  dwarf_r14,
  dwarf_r15,
  dwarf_r16,
  dwarf_r17,
  dwarf_r18,
  dwarf_r19,
  dwarf_r20, // First callee-saved
  dwarf_r21,
  dwarf_r22,
  dwarf_r23,
  dwarf_r24,
  dwarf_r25,
  dwarf_r26,
  dwarf_r27,
  dwarf_r28,
  dwarf_fp, // r29 - Frame pointer
  dwarf_ep, // r30 - Element pointer
  dwarf_lp, // r31 - Link pointer (return address)

  // System registers
  dwarf_pc = 64,    // Program counter
  dwarf_psw = 65,   // Program status word
  dwarf_eipc = 66,  // Exception/interrupt saved PC
  dwarf_eipsw = 67, // Exception/interrupt saved PSW
  dwarf_fepc = 68,  // Fatal error saved PC
  dwarf_fepsw = 69, // Fatal error saved PSW
  dwarf_ecr = 70,   // Exception cause register
  dwarf_ctpc = 71,  // CALLT saved PC
  dwarf_ctpsw = 72, // CALLT saved PSW
  dwarf_ctbp = 73,  // CALLT base pointer
  dwarf_dbpc = 74,  // Debug saved PC
  dwarf_dbpsw = 75  // Debug saved PSW
};

static const RegisterInfo g_register_infos[] = {
    // General purpose registers r0-r31
    {
        "r0",
        "zero",
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r0, dwarf_r0, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r1",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r1, dwarf_r1, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r2",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r2, dwarf_r2, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r3",
        "sp",
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_sp, dwarf_sp, LLDB_REGNUM_GENERIC_SP, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r4",
        "gp",
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_gp, dwarf_gp, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r5",
        "tp",
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_tp, dwarf_tp, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r6",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r6, dwarf_r6, LLDB_REGNUM_GENERIC_ARG1, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r7",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r7, dwarf_r7, LLDB_REGNUM_GENERIC_ARG2, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r8",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r8, dwarf_r8, LLDB_REGNUM_GENERIC_ARG3, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r9",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r9, dwarf_r9, LLDB_REGNUM_GENERIC_ARG4, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r10",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r10, dwarf_r10, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r11",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r11, dwarf_r11, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r12",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r12, dwarf_r12, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r13",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r13, dwarf_r13, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r14",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r14, dwarf_r14, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r15",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r15, dwarf_r15, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r16",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r16, dwarf_r16, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r17",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r17, dwarf_r17, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r18",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r18, dwarf_r18, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r19",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r19, dwarf_r19, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r20",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r20, dwarf_r20, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r21",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r21, dwarf_r21, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r22",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r22, dwarf_r22, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r23",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r23, dwarf_r23, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r24",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r24, dwarf_r24, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r25",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r25, dwarf_r25, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r26",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r26, dwarf_r26, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r27",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r27, dwarf_r27, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r28",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_r28, dwarf_r28, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r29",
        "fp",
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_fp, dwarf_fp, LLDB_REGNUM_GENERIC_FP, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r30",
        "ep",
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_ep, dwarf_ep, LLDB_INVALID_REGNUM, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    {
        "r31",
        "lp",
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_lp, dwarf_lp, LLDB_REGNUM_GENERIC_RA, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    // Program counter
    {
        "pc",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_pc, dwarf_pc, LLDB_REGNUM_GENERIC_PC, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    },
    // Program status word
    {
        "psw",
        nullptr,
        4,
        0,
        eEncodingUint,
        eFormatHex,
        {dwarf_psw, dwarf_psw, LLDB_REGNUM_GENERIC_FLAGS, LLDB_INVALID_REGNUM,
         LLDB_INVALID_REGNUM},
        nullptr,
        nullptr,
        nullptr,
    }};

static const uint32_t k_num_register_infos =
    sizeof(g_register_infos) / sizeof(RegisterInfo);

const lldb_private::RegisterInfo *
ABISysV_v850::GetRegisterInfoArray(uint32_t &count) {
  count = k_num_register_infos;
  return g_register_infos;
}

size_t ABISysV_v850::GetRedZoneSize() const {
  // V850 does not use a red zone
  return 0;
}

//------------------------------------------------------------------
// Static Functions
//------------------------------------------------------------------

ABISP
ABISysV_v850::CreateInstance(lldb::ProcessSP process_sp, const ArchSpec &arch) {
  if (arch.GetTriple().getArch() == llvm::Triple::v850) {
    return ABISP(
        new ABISysV_v850(std::move(process_sp), MakeMCRegisterInfo(arch)));
  }
  return ABISP();
}

bool ABISysV_v850::PrepareTrivialCall(Thread &thread, lldb::addr_t sp,
                                      lldb::addr_t pc, lldb::addr_t ra,
                                      llvm::ArrayRef<addr_t> args) const {
  // V850 calling convention:
  // - Arguments in r6-r9, additional arguments on stack
  // - Return address in r31 (LP)
  // - Stack pointer in r3 (SP)

  RegisterContext *reg_ctx = thread.GetRegisterContext().get();
  if (!reg_ctx)
    return false;

  // Set up argument registers (r6-r9)
  const RegisterInfo *reg_info;
  for (size_t i = 0; i < args.size() && i < 4; ++i) {
    reg_info = reg_ctx->GetRegisterInfo(eRegisterKindDWARF, dwarf_r6 + i);
    if (reg_info)
      reg_ctx->WriteRegisterFromUnsigned(reg_info, args[i]);
  }

  // Set SP
  reg_info = reg_ctx->GetRegisterInfo(eRegisterKindDWARF, dwarf_sp);
  if (reg_info)
    reg_ctx->WriteRegisterFromUnsigned(reg_info, sp);

  // Set LP (return address)
  reg_info = reg_ctx->GetRegisterInfo(eRegisterKindDWARF, dwarf_lp);
  if (reg_info)
    reg_ctx->WriteRegisterFromUnsigned(reg_info, ra);

  // Set PC
  reg_info = reg_ctx->GetRegisterInfo(eRegisterKindDWARF, dwarf_pc);
  if (reg_info)
    reg_ctx->WriteRegisterFromUnsigned(reg_info, pc);

  return true;
}

bool ABISysV_v850::GetArgumentValues(Thread &thread, ValueList &values) const {
  // V850 passes first 4 arguments in r6-r9, rest on stack
  RegisterContext *reg_ctx = thread.GetRegisterContext().get();
  if (!reg_ctx)
    return false;

  const uint32_t num_values = values.GetSize();
  uint32_t arg_reg = dwarf_r6;

  for (uint32_t value_idx = 0; value_idx < num_values; ++value_idx) {
    Value *value = values.GetValueAtIndex(value_idx);
    if (!value)
      return false;

    CompilerType compiler_type = value->GetCompilerType();
    if (!compiler_type)
      return false;

    std::optional<uint64_t> opt_byte_size =
        llvm::expectedToOptional(compiler_type.GetByteSize(&thread));
    if (!opt_byte_size)
      return false;
    uint64_t byte_size = *opt_byte_size;

    // For now, only handle scalar types that fit in registers
    if (byte_size > 4 || arg_reg > dwarf_r9)
      return false;

    const RegisterInfo *reg_info =
        reg_ctx->GetRegisterInfo(eRegisterKindDWARF, arg_reg);
    if (!reg_info)
      return false;

    uint64_t raw_value = reg_ctx->ReadRegisterAsUnsigned(reg_info, 0);

    // Mask to appropriate size
    if (byte_size == 1)
      raw_value &= 0xFF;
    else if (byte_size == 2)
      raw_value &= 0xFFFF;

    value->GetScalar() = raw_value;
    value->SetValueType(Value::ValueType::Scalar);
    ++arg_reg;
  }

  return true;
}

Status ABISysV_v850::SetReturnValueObject(lldb::StackFrameSP &frame_sp,
                                          lldb::ValueObjectSP &new_value_sp) {
  Status result;
  if (!new_value_sp) {
    result = Status::FromErrorString("Empty value object for return value.");
    return result;
  }

  CompilerType compiler_type = new_value_sp->GetCompilerType();
  if (!compiler_type) {
    result = Status::FromErrorString("Null compiler type for return value.");
    return result;
  }

  RegisterContext *reg_ctx = frame_sp->GetThread()->GetRegisterContext().get();
  if (!reg_ctx) {
    result = Status::FromErrorString("Could not get register context.");
    return result;
  }

  bool is_signed = false;
  if (!compiler_type.IsIntegerOrEnumerationType(is_signed) &&
      !compiler_type.IsPointerType()) {
    result = Status::FromErrorString(
        "We don't support returning other types at present");
    return result;
  }

  DataExtractor data;
  size_t num_bytes = new_value_sp->GetData(data, result);
  if (result.Fail()) {
    result = Status::FromErrorStringWithFormat(
        "Couldn't convert return value to raw data: %s", result.AsCString());
    return result;
  }

  // V850 uses r10 for return values (r10:r11 for 64-bit)
  if (num_bytes <= 8) {
    offset_t offset = 0;
    uint64_t raw_value = data.GetMaxU64(&offset, num_bytes);

    const RegisterInfo *r10_info =
        reg_ctx->GetRegisterInfo(eRegisterKindDWARF, dwarf_r10);
    if (!reg_ctx->WriteRegisterFromUnsigned(r10_info, raw_value & 0xFFFFFFFF)) {
      result = Status::FromErrorString("Couldn't write value to register r10");
      return result;
    }

    if (num_bytes > 4) {
      // Write upper 32 bits to r11
      const RegisterInfo *r11_info =
          reg_ctx->GetRegisterInfo(eRegisterKindDWARF, dwarf_r11);
      if (!reg_ctx->WriteRegisterFromUnsigned(r11_info, raw_value >> 32)) {
        result =
            Status::FromErrorString("Couldn't write value to register r11");
        return result;
      }
    }

    return result;
  }

  result = Status::FromErrorString(
      "We don't support returning large values at present.");
  return result;
}

// Helper function to set scalar value with proper sign handling
static void SetIntegerScalar(Scalar &scalar, uint64_t raw_value,
                             uint32_t byte_size, bool is_signed) {
  switch (byte_size) {
  case 1:
    raw_value &= 0xFF;
    if (is_signed)
      scalar = static_cast<int8_t>(raw_value);
    else
      scalar = static_cast<uint8_t>(raw_value);
    break;
  case 2:
    raw_value &= 0xFFFF;
    if (is_signed)
      scalar = static_cast<int16_t>(raw_value);
    else
      scalar = static_cast<uint16_t>(raw_value);
    break;
  case 4:
    raw_value &= 0xFFFFFFFF;
    if (is_signed)
      scalar = static_cast<int32_t>(raw_value);
    else
      scalar = static_cast<uint32_t>(raw_value);
    break;
  case 8:
    if (is_signed)
      scalar = static_cast<int64_t>(raw_value);
    else
      scalar = static_cast<uint64_t>(raw_value);
    break;
  default:
    break;
  }
}

ValueObjectSP ABISysV_v850::GetReturnValueObjectSimple(
    Thread &thread, CompilerType &return_compiler_type) const {
  ValueObjectSP return_valobj_sp;

  if (!return_compiler_type)
    return return_valobj_sp;

  RegisterContext *reg_ctx = thread.GetRegisterContext().get();
  if (!reg_ctx)
    return return_valobj_sp;

  Value value;
  value.SetCompilerType(return_compiler_type);

  const uint32_t type_flags = return_compiler_type.GetTypeInfo();
  std::optional<uint64_t> opt_byte_size =
      llvm::expectedToOptional(return_compiler_type.GetByteSize(&thread));
  if (!opt_byte_size)
    return return_valobj_sp;
  uint64_t byte_size = *opt_byte_size;

  // V850 return values:
  // - 8/16/32-bit integers and pointers: r10
  // - 64-bit integers: r10:r11 (r10=low, r11=high)
  // - floats (if FPU): r10 (bit pattern)
  // - doubles (if FPU): r10:r11 (bit pattern)

  const RegisterInfo *r10_info =
      reg_ctx->GetRegisterInfo(eRegisterKindDWARF, dwarf_r10);
  const RegisterInfo *r11_info =
      reg_ctx->GetRegisterInfo(eRegisterKindDWARF, dwarf_r11);

  if (!r10_info)
    return return_valobj_sp;

  uint64_t raw_value = reg_ctx->ReadRegisterAsUnsigned(r10_info, 0);

  if (byte_size > 4 && byte_size <= 8) {
    // 64-bit value: combine r10 (low) and r11 (high)
    if (!r11_info)
      return return_valobj_sp;
    uint64_t high_value = reg_ctx->ReadRegisterAsUnsigned(r11_info, 0);
    raw_value = (raw_value & 0xFFFFFFFF) | (high_value << 32);
  }

  if (type_flags & eTypeIsInteger) {
    const bool is_signed = (type_flags & eTypeIsSigned) != 0;
    SetIntegerScalar(value.GetScalar(), raw_value, byte_size, is_signed);
    value.SetValueType(Value::ValueType::Scalar);
    return_valobj_sp = ValueObjectConstResult::Create(
        thread.GetStackFrameAtIndex(0).get(), value, ConstString(""));
  } else if (type_flags & eTypeIsPointer) {
    value.GetScalar() = static_cast<uint32_t>(raw_value & 0xFFFFFFFF);
    value.SetValueType(Value::ValueType::Scalar);
    return_valobj_sp = ValueObjectConstResult::Create(
        thread.GetStackFrameAtIndex(0).get(), value, ConstString(""));
  } else if (type_flags & eTypeIsFloat) {
    if (byte_size == 4) {
      // float: interpret r10 as float bit pattern
      uint32_t float_bits = static_cast<uint32_t>(raw_value);
      value.GetScalar() = *reinterpret_cast<float *>(&float_bits);
    } else if (byte_size == 8) {
      // double: interpret r10:r11 as double bit pattern
      value.GetScalar() = *reinterpret_cast<double *>(&raw_value);
    }
    value.SetValueType(Value::ValueType::Scalar);
    return_valobj_sp = ValueObjectConstResult::Create(
        thread.GetStackFrameAtIndex(0).get(), value, ConstString(""));
  }

  return return_valobj_sp;
}

ValueObjectSP ABISysV_v850::GetReturnValueObjectImpl(
    Thread &thread, CompilerType &return_compiler_type) const {
  return GetReturnValueObjectSimple(thread, return_compiler_type);
}

// Called when we are on the first instruction of a new function
// At function entry on V850:
// - CFA = SP (stack pointer at function entry)
// - Return address is in LP (r31)
// - Callee-saved registers (r20-r29, EP, LP) have their original values
//
// V850 Calling Convention:
// - Arguments: r6-r9, additional arguments on stack
// - Return value: r10 (32-bit), r10:r11 (64-bit)
// - Callee-saved: r20-r29, EP (r30), LP (r31)
// - Caller-saved: r1, r6-r19
// - Stack pointer: r3 (SP)
// - Frame pointer: r29 (when used)
// - Link pointer: r31 (LP) - holds return address
UnwindPlanSP ABISysV_v850::CreateFunctionEntryUnwindPlan() {
  UnwindPlan::Row row;

  // CFA = SP + 0 (at function entry, before prologue)
  row.GetCFAValue().SetIsRegisterPlusOffset(dwarf_sp, 0);

  // PC is in LP (r31) at function entry - this is how we unwind
  row.SetRegisterLocationToRegister(dwarf_pc, dwarf_lp, true);

  // SP = CFA (stack pointer is the CFA at entry)
  row.SetRegisterLocationToIsCFAPlusOffset(dwarf_sp, 0, true);

  // LP contains the return address, which is also where we get PC
  row.SetRegisterLocationToSame(dwarf_lp, true);

  auto plan_sp = std::make_shared<UnwindPlan>(eRegisterKindDWARF);
  plan_sp->AppendRow(std::move(row));
  plan_sp->SetSourceName("v850 at-func-entry default");
  plan_sp->SetSourcedFromCompiler(eLazyBoolNo);
  plan_sp->SetReturnAddressRegister(dwarf_lp);
  return plan_sp;
}

// Default unwind plan when we don't have CFI information.
// This is a fallback used when no debug info or eh_frame is available.
//
// V850 Frame Layout with Frame Pointer (r29):
//
// High Address
// +----------------+
// |  Arguments     |
// +----------------+ <- CFA (Caller's SP)
// |  Saved LP      |  (CFA - 4, saved first by PREPARE)
// +----------------+
// |  Saved EP      |  (CFA - 8, if saved)
// +----------------+
// |  Saved FP(r29) |  (CFA - offset) <- FP points here
// +----------------+
// |  Saved r28...  |
// +----------------+
// |  Local Vars    |
// +----------------+ <- SP
// Low Address
//
// When using frame pointer, FP points to where the old FP was saved.
// The saved LP (return address) is typically at FP + 4 (assuming standard
// PREPARE layout where LP is saved right before FP).
//
// Assumptions for default plan:
// - Frame pointer is being used
// - CFA = FP + 8 (LP at CFA-4, FP at CFA-8)
// - Old FP at [FP] = [CFA - 8]
// - LP (return address) at [FP + 4] = [CFA - 4]
UnwindPlanSP ABISysV_v850::CreateDefaultUnwindPlan() {
  UnwindPlan::Row row;

  // Use generic register kinds for the default plan
  // CFA = FP + 8 (assuming LP and FP are the first two saved registers)
  row.GetCFAValue().SetIsRegisterPlusOffset(LLDB_REGNUM_GENERIC_FP, 8);

  // Return address (PC) is at CFA - 4 (where LP was saved)
  row.SetRegisterLocationToAtCFAPlusOffset(LLDB_REGNUM_GENERIC_PC, -4, true);

  // Old frame pointer is at CFA - 8 (where FP was saved)
  row.SetRegisterLocationToAtCFAPlusOffset(LLDB_REGNUM_GENERIC_FP, -8, true);

  // SP = CFA (after unwinding, SP should be at caller's SP)
  row.SetRegisterLocationToIsCFAPlusOffset(LLDB_REGNUM_GENERIC_SP, 0, true);

  auto plan_sp = std::make_shared<UnwindPlan>(eRegisterKindGeneric);
  plan_sp->AppendRow(std::move(row));
  plan_sp->SetSourceName("v850 default unwind plan");
  plan_sp->SetSourcedFromCompiler(eLazyBoolNo);
  plan_sp->SetUnwindPlanValidAtAllInstructions(eLazyBoolNo);
  plan_sp->SetReturnAddressRegister(LLDB_REGNUM_GENERIC_RA);
  return plan_sp;
}

bool ABISysV_v850::RegisterIsVolatile(const RegisterInfo *reg_info) {
  return !RegisterIsCalleeSaved(reg_info);
}

bool ABISysV_v850::RegisterIsCalleeSaved(const RegisterInfo *reg_info) {
  if (!reg_info)
    return false;

  // Get DWARF register number
  uint32_t dwarf_reg = reg_info->kinds[eRegisterKindDWARF];

  // Callee-saved registers on V850: r20-r29, r31 (LP)
  // r30 (EP) is also callee-saved
  if (dwarf_reg >= dwarf_r20 && dwarf_reg <= dwarf_fp)
    return true;
  if (dwarf_reg == dwarf_ep)
    return true;
  if (dwarf_reg == dwarf_lp)
    return true;

  return false;
}

void ABISysV_v850::Initialize() {
  PluginManager::RegisterPlugin(
      GetPluginNameStatic(), "System V ABI for V850 targets", CreateInstance);
}

void ABISysV_v850::Terminate() {
  PluginManager::UnregisterPlugin(CreateInstance);
}
