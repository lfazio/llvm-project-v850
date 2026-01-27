//===-- ArchitectureV850.h --------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLDB_SOURCE_PLUGINS_ARCHITECTURE_V850_ARCHITECTUREV850_H
#define LLDB_SOURCE_PLUGINS_ARCHITECTURE_V850_ARCHITECTUREV850_H

#include "lldb/Core/Architecture.h"

namespace lldb_private {

class ArchitectureV850 : public Architecture {
public:
  static llvm::StringRef GetPluginNameStatic() { return "v850"; }
  static void Initialize();
  static void Terminate();

  static std::unique_ptr<Architecture> Create(const ArchSpec &arch);

  llvm::StringRef GetPluginName() override { return GetPluginNameStatic(); }

  void OverrideStopInfo(Thread &thread) const override {}

  lldb::addr_t GetBreakableLoadAddress(lldb::addr_t addr,
                                       Target &target) const override;

  lldb::addr_t GetCallableLoadAddress(lldb::addr_t load_addr,
                                      AddressClass addr_class) const override;

  lldb::addr_t GetOpcodeLoadAddress(lldb::addr_t load_addr,
                                    AddressClass addr_class) const override;

private:
  ArchitectureV850() = default;
};

} // namespace lldb_private

#endif // LLDB_SOURCE_PLUGINS_ARCHITECTURE_V850_ARCHITECTUREV850_H
