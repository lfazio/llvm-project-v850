//===-- V850TargetObjectFile.cpp - V850 Object Files ----------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the V850 implementation of TargetLoweringObjectFile.
//
//===----------------------------------------------------------------------===//

#include "V850TargetObjectFile.h"
#include "V850Subtarget.h"
#include "V850TargetMachine.h"
#include "llvm/BinaryFormat/ELF.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCSectionELF.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Target/TargetMachine.h"

using namespace llvm;

static cl::opt<unsigned>
    SSThreshold("v850-ssection-threshold", cl::Hidden,
                cl::desc("Small data and bss section threshold size (default=8)"),
                cl::init(8));

static cl::opt<bool>
    LocalSData("v850-local-sdata", cl::Hidden,
               cl::desc("V850: Use gp_rel for object-local data."),
               cl::init(true));

static cl::opt<bool>
    ExternSData("v850-extern-sdata", cl::Hidden,
                cl::desc("V850: Use gp_rel for data that is not defined by the "
                         "current object."),
                cl::init(true));

void V850ELFTargetObjectFile::Initialize(MCContext &Ctx,
                                         const TargetMachine &TM) {
  TargetLoweringObjectFileELF::Initialize(Ctx, TM);

  // V850 uses .sdata and .sbss sections for small data.
  // The SHF_V850_GPREL flag indicates GP-relative addressing.
  // Note: ELF::SHF_V850_GPREL may need to be defined; using MIPS equivalent
  // as placeholder.
  SmallDataSection = getContext().getELFSection(
      ".sdata", ELF::SHT_PROGBITS, ELF::SHF_WRITE | ELF::SHF_ALLOC);

  SmallBSSSection = getContext().getELFSection(
      ".sbss", ELF::SHT_NOBITS, ELF::SHF_WRITE | ELF::SHF_ALLOC);

  this->TM = &static_cast<const V850TargetMachine &>(TM);
}

/// Return true if the size is within the small data threshold.
static bool IsInSmallSection(uint64_t Size) {
  // GCC has traditionally not treated zero-sized objects as small data.
  return Size > 0 && Size <= SSThreshold;
}

bool V850ELFTargetObjectFile::IsGlobalInSmallSection(
    const GlobalObject *GO, const TargetMachine &TM) const {
  // Check if global is a declaration first, since getKindForGlobal() is only
  // allowed for global definitions.
  if (GO->isDeclaration() || GO->hasAvailableExternallyLinkage())
    return IsGlobalInSmallSectionImpl(GO, TM);

  return IsGlobalInSmallSection(GO, TM, getKindForGlobal(GO, TM));
}

bool V850ELFTargetObjectFile::IsGlobalInSmallSection(const GlobalObject *GO,
                                                      const TargetMachine &TM,
                                                      SectionKind Kind) const {
  return IsGlobalInSmallSectionImpl(GO, TM) &&
         (Kind.isData() || Kind.isBSS() || Kind.isCommon() || Kind.isReadOnly());
}

bool V850ELFTargetObjectFile::IsGlobalInSmallSectionImpl(
    const GlobalObject *GO, const TargetMachine &TM) const {
  // Only global variables, not functions.
  const GlobalVariable *GVA = dyn_cast<GlobalVariable>(GO);
  if (!GVA)
    return false;

  // If the variable has an explicit section, check if it's a small section.
  if (GVA->hasSection()) {
    StringRef Section = GVA->getSection();

    // Explicitly placing any variable in the small data section overrides
    // the global threshold.
    if (Section == ".sdata" || Section == ".sbss")
      return true;

    // Otherwise, don't use GP-relative addressing for other explicit sections.
    return false;
  }

  // Enforce -v850-local-sdata.
  if (!LocalSData && GVA->hasLocalLinkage())
    return false;

  // Enforce -v850-extern-sdata.
  if (!ExternSData && ((GVA->hasExternalLinkage() && GVA->isDeclaration()) ||
                       GVA->hasCommonLinkage()))
    return false;

  Type *Ty = GVA->getValueType();

  // The type must be sized.
  if (!Ty->isSized())
    return false;

  return IsInSmallSection(GVA->getDataLayout().getTypeAllocSize(Ty));
}

MCSection *V850ELFTargetObjectFile::SelectSectionForGlobal(
    const GlobalObject *GO, SectionKind Kind, const TargetMachine &TM) const {
  // Handle small section classification.
  if (Kind.isBSS() && IsGlobalInSmallSection(GO, TM, Kind))
    return SmallBSSSection;
  if (Kind.isData() && IsGlobalInSmallSection(GO, TM, Kind))
    return SmallDataSection;
  if (Kind.isReadOnly() && IsGlobalInSmallSection(GO, TM, Kind))
    return SmallDataSection;

  // Otherwise, use the default ELF section handling.
  return TargetLoweringObjectFileELF::SelectSectionForGlobal(GO, Kind, TM);
}

bool V850ELFTargetObjectFile::IsConstantInSmallSection(
    const DataLayout &DL, const Constant *CN, const TargetMachine &TM) const {
  return LocalSData && IsInSmallSection(DL.getTypeAllocSize(CN->getType()));
}

MCSection *V850ELFTargetObjectFile::getSectionForConstant(
    const DataLayout &DL, SectionKind Kind, const Constant *C,
    Align &Alignment) const {
  if (IsConstantInSmallSection(DL, C, *TM))
    return SmallDataSection;

  return TargetLoweringObjectFileELF::getSectionForConstant(DL, Kind, C,
                                                            Alignment);
}
