//===-- ArchitectureV850.cpp ----------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "ArchitectureV850.h"
#include "lldb/Core/PluginManager.h"
#include "lldb/Target/Target.h"
#include "lldb/Utility/ArchSpec.h"

using namespace lldb;
using namespace lldb_private;

LLDB_PLUGIN_DEFINE(ArchitectureV850)

void ArchitectureV850::Initialize() {
  PluginManager::RegisterPlugin(GetPluginNameStatic(),
                                "V850-specific algorithms",
                                &ArchitectureV850::Create);
}

void ArchitectureV850::Terminate() {
  PluginManager::UnregisterPlugin(&ArchitectureV850::Create);
}

std::unique_ptr<Architecture> ArchitectureV850::Create(const ArchSpec &arch) {
  if (arch.GetMachine() != llvm::Triple::v850)
    return nullptr;
  return std::unique_ptr<Architecture>(new ArchitectureV850());
}

addr_t ArchitectureV850::GetBreakableLoadAddress(addr_t addr,
                                                 Target &target) const {
  // V850 has no delay slots, so breakpoints can be set at any instruction
  // boundary. Instructions are either 16-bit or 32-bit, always aligned to
  // 2-byte boundaries.
  return addr;
}

addr_t ArchitectureV850::GetCallableLoadAddress(addr_t load_addr,
                                                AddressClass addr_class) const {
  // V850 has no ISA mode bits in addresses (unlike ARM Thumb or MIPS16).
  // All addresses are plain instruction addresses.
  return load_addr;
}

addr_t ArchitectureV850::GetOpcodeLoadAddress(addr_t load_addr,
                                              AddressClass addr_class) const {
  // V850 has no ISA mode bits, so opcode address equals load address.
  return load_addr;
}
