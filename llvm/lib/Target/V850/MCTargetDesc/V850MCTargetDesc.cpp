//===-- V850MCTargetDesc.cpp - V850 Target Descriptions -------------------===//
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

#include "V850MCTargetDesc.h"
#include "TargetInfo/V850TargetInfo.h"
#include "V850InstPrinter.h"
#include "V850MCAsmInfo.h"
#include "llvm/MC/MCDwarf.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Compiler.h"
#include "llvm/TargetParser/Triple.h"

#define GET_INSTRINFO_MC_DESC
#define ENABLE_INSTR_PREDICATE_VERIFIER
#include "V850GenInstrInfo.inc"

#define GET_SUBTARGETINFO_MC_DESC
#include "V850GenSubtargetInfo.inc"

#define GET_REGINFO_MC_DESC
#include "V850GenRegisterInfo.inc"

using namespace llvm;

static MCInstrInfo *createV850MCInstrInfo() {
  MCInstrInfo *X = new MCInstrInfo();
  InitV850MCInstrInfo(X);
  return X;
}

static MCRegisterInfo *createV850MCRegisterInfo(const Triple & /*TT*/) {
  MCRegisterInfo *X = new MCRegisterInfo();
  InitV850MCRegisterInfo(X, V850::LP);
  return X;
}

static MCAsmInfo *createV850MCAsmInfo(const MCRegisterInfo &MRI,
                                      const Triple &TT,
                                      const MCTargetOptions &Options) {
  MCAsmInfo *MAI = new V850MCAsmInfo(TT, Options);

  // Set up initial frame state: CFA = SP + 0
  // SP is R3 on V850
  unsigned SP = MRI.getDwarfRegNum(V850::SP, true);
  MCCFIInstruction Inst = MCCFIInstruction::cfiDefCfa(nullptr, SP, 0);
  MAI->addInitialFrameState(Inst);

  return MAI;
}

static MCSubtargetInfo *createV850MCSubtargetInfo(const Triple &TT,
                                                  StringRef CPU, StringRef FS) {
  if (CPU.empty())
    CPU = "generic";
  return createV850MCSubtargetInfoImpl(TT, CPU, /*TuneCPU*/ CPU, FS);
}

static MCInstPrinter *createV850MCInstPrinter(const Triple & /*T*/,
                                              unsigned SyntaxVariant,
                                              const MCAsmInfo &MAI,
                                              const MCInstrInfo &MII,
                                              const MCRegisterInfo &MRI) {
  if (SyntaxVariant == 0)
    return new V850InstPrinter(MAI, MII, MRI);
  return nullptr;
}

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void LLVMInitializeV850TargetMC() {
  Target &T = getTheV850Target();

  // Register the MC asm info with initial frame state.
  TargetRegistry::RegisterMCAsmInfo(T, createV850MCAsmInfo);

  // Register the MC instruction info.
  TargetRegistry::RegisterMCInstrInfo(T, createV850MCInstrInfo);

  // Register the MC register info.
  TargetRegistry::RegisterMCRegInfo(T, createV850MCRegisterInfo);

  // Register the MC subtarget info.
  TargetRegistry::RegisterMCSubtargetInfo(T, createV850MCSubtargetInfo);

  // Register the MCInstPrinter.
  TargetRegistry::RegisterMCInstPrinter(T, createV850MCInstPrinter);

  // Register the MC code emitter.
  TargetRegistry::RegisterMCCodeEmitter(T, createV850MCCodeEmitter);

  // Register the ASM backend.
  TargetRegistry::RegisterMCAsmBackend(T, createV850AsmBackend);
}
