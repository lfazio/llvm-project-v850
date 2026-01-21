//===-- V850TargetObjectFile.h - V850 Object Info ---------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains declarations for V850 ELF object file lowering.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V850_V850TARGETOBJECTFILE_H
#define LLVM_LIB_TARGET_V850_V850TARGETOBJECTFILE_H

#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"

namespace llvm {

class V850TargetMachine;

class V850ELFTargetObjectFile : public TargetLoweringObjectFileELF {
  MCSection *SmallDataSection = nullptr;
  MCSection *SmallBSSSection = nullptr;
  const V850TargetMachine *TM = nullptr;

  bool IsGlobalInSmallSectionImpl(const GlobalObject *GO,
                                  const TargetMachine &TM) const;

public:
  void Initialize(MCContext &Ctx, const TargetMachine &TM) override;

  /// Return true if this global address should be placed into the small
  /// data/bss section. These sections use GP-relative addressing.
  bool IsGlobalInSmallSection(const GlobalObject *GO,
                              const TargetMachine &TM) const;

  bool IsGlobalInSmallSection(const GlobalObject *GO, const TargetMachine &TM,
                              SectionKind Kind) const;

  MCSection *SelectSectionForGlobal(const GlobalObject *GO, SectionKind Kind,
                                    const TargetMachine &TM) const override;

  /// Return true if this constant should be placed into the small data section.
  bool IsConstantInSmallSection(const DataLayout &DL, const Constant *CN,
                                const TargetMachine &TM) const;

  MCSection *getSectionForConstant(const DataLayout &DL, SectionKind Kind,
                                   const Constant *C,
                                   Align &Alignment) const override;
};

} // end namespace llvm

#endif // LLVM_LIB_TARGET_V850_V850TARGETOBJECTFILE_H
