//===-- V850TargetMachine.cpp - Define TargetMachine for V850 -------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Implements the info about V850 target spec.
//
//===----------------------------------------------------------------------===//

#include "V850TargetMachine.h"
#include "TargetInfo/V850TargetInfo.h"
#include "V850.h"
#include "V850MachineFunctionInfo.h"
#include "V850Subtarget.h"
#include "V850TargetObjectFile.h"
#include "V850TargetTransformInfo.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/CodeGen/TargetPassConfig.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/PassRegistry.h"

using namespace llvm;

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void LLVMInitializeV850Target() {
  // Register the target.
  RegisterTargetMachine<V850TargetMachine> X(getTheV850Target());

  // Initialize passes
  PassRegistry &PR = *PassRegistry::getPassRegistry();
  initializeV850DAGToDAGISelLegacyPass(PR);
  initializeV850LoadStoreOptimizerPass(PR);
  initializeV850PeepholeOptimizerPass(PR);
}

static std::string computeDataLayout(const Triple &TT) {
  // V850 is little-endian, 32-bit pointers and integers
  // e = little endian
  // m:e = ELF mangling
  // p:32:32 = 32-bit pointers with 32-bit alignment
  // i64:32 = 64-bit integers with 32-bit alignment
  // f64:32 = 64-bit floats with 32-bit alignment
  // a:0:32 = aggregates with 32-bit alignment
  // n32 = native integer width is 32-bit
  // S32 = stack natural alignment is 32-bit
  return "e-m:e-p:32:32-i64:32-f64:32-a:0:32-n32-S32";
}

V850TargetMachine::V850TargetMachine(const Target &T, const Triple &TT,
                                     StringRef CPU, StringRef FS,
                                     const TargetOptions &Options,
                                     std::optional<Reloc::Model> RM,
                                     std::optional<CodeModel::Model> CM,
                                     CodeGenOptLevel OL, bool JIT)
    : CodeGenTargetMachineImpl(T, computeDataLayout(TT), TT, CPU, FS, Options,
                               RM.value_or(Reloc::Static),
                               CM.value_or(CodeModel::Small), OL),
      TLOF(std::make_unique<V850ELFTargetObjectFile>()) {
  initAsmInfo();
}

V850TargetMachine::~V850TargetMachine() = default;

const V850Subtarget *
V850TargetMachine::getSubtargetImpl(const Function &F) const {
  Attribute CPUAttr = F.getFnAttribute("target-cpu");
  Attribute FSAttr = F.getFnAttribute("target-features");

  std::string CPU =
      CPUAttr.isValid() ? CPUAttr.getValueAsString().str() : TargetCPU;
  std::string FS =
      FSAttr.isValid() ? FSAttr.getValueAsString().str() : TargetFS;

  std::string Key = CPU + FS;
  auto &I = SubtargetMap[Key];
  if (!I) {
    // This needs to be done before we create a new subtarget since any
    // creation will depend on the TM and the code generation flags on the
    // function that reside in TargetOptions.
    resetTargetOptions(F);
    I = std::make_unique<V850Subtarget>(TargetTriple, CPU, FS, *this);
  }
  return I.get();
}

namespace {

class V850PassConfig : public TargetPassConfig {
public:
  V850PassConfig(V850TargetMachine &TM, PassManagerBase &PM)
      : TargetPassConfig(TM, PM) {}

  V850TargetMachine &getV850TargetMachine() const {
    return getTM<V850TargetMachine>();
  }

  void addIRPasses() override;
  bool addPreISel() override;
  bool addInstSelector() override;
  void addPreRegAlloc() override;
  void addPreEmitPass() override;
};

} // end anonymous namespace

TargetPassConfig *V850TargetMachine::createPassConfig(PassManagerBase &PM) {
  return new V850PassConfig(*this, PM);
}

TargetTransformInfo
V850TargetMachine::getTargetTransformInfo(const Function &F) const {
  return TargetTransformInfo(std::make_unique<V850TTIImpl>(this, F));
}

void V850PassConfig::addIRPasses() {
  // Add the AtomicExpandPass to expand atomic RMW operations to cmpxchg loops
  // V850E2M has CAXI for 32-bit compare-and-swap
  addPass(createAtomicExpandLegacyPass());

  TargetPassConfig::addIRPasses();
}

bool V850PassConfig::addPreISel() {
  // Hardware loop conversion for RH850G3M+ LOOP instruction.
  // The HardwareLoops pass converts counted loops to use hardware loop
  // intrinsics, which are then lowered to LOOP instructions in ISel.
  if (getOptLevel() != CodeGenOptLevel::None)
    addPass(createHardwareLoopsLegacyPass());

  return false;
}

bool V850PassConfig::addInstSelector() {
  addPass(createV850ISelDag(getV850TargetMachine(), getOptLevel()));
  return false;
}

void V850PassConfig::addPreRegAlloc() {
  // Enable if-conversion using CMOV instructions for optimized builds.
  // This converts simple if-then-else patterns to conditional moves.
  if (getOptLevel() != CodeGenOptLevel::None)
    addPass(&EarlyIfConverterLegacyID);
}

void V850PassConfig::addPreEmitPass() {
  // Peephole optimizer: performs local optimizations like folding MOV+ADD
  // to MOV immediate, removing redundant ANDI after zero-extending loads.
  if (getOptLevel() != CodeGenOptLevel::None)
    addPass(createV850PeepholeOptimizerPass());

  // Load/store optimizer: promotes 32-bit LD.W/ST.W to 16-bit SLD.W/SST.W
  // when EP is the base and displacement fits. Must run before branch
  // relaxation since it changes instruction sizes.
  addPass(createV850LoadStoreOptimizerPass());

  // Branch relaxation must run after all other passes that modify code layout.
  // It expands conditional branches that are out of range by inverting the
  // condition and inserting an unconditional branch to the original target.
  addPass(&BranchRelaxationPassID);
}

MachineFunctionInfo *V850TargetMachine::createMachineFunctionInfo(
    BumpPtrAllocator &Allocator, const Function &F,
    const TargetSubtargetInfo *STI) const {
  return V850MachineFunctionInfo::create<V850MachineFunctionInfo>(Allocator, F,
                                                                  STI);
}
