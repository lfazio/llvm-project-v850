//===-- V850ISelLowering.cpp - V850 DAG Lowering Implementation -----------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements the V850TargetLowering class.
//
//===----------------------------------------------------------------------===//

#include "V850ISelLowering.h"
#include "MCTargetDesc/V850BaseInfo.h"
#include "V850.h"
#include "V850MachineFunctionInfo.h"
#include "V850RegisterInfo.h"
#include "V850Subtarget.h"
#include "V850TargetMachine.h"
#include "V850TargetObjectFile.h"
#include "llvm/CodeGen/CallingConvLower.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineJumpTableInfo.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/IR/CallingConv.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/IntrinsicsV850.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

#define DEBUG_TYPE "v850-lower"

#include "V850GenCallingConv.inc"

V850TargetLowering::V850TargetLowering(const TargetMachine &TM,
                                       const V850Subtarget &STI)
    : TargetLowering(TM), Subtarget(STI) {

  // Set up the register classes
  addRegisterClass(MVT::i32, &V850::GPRRegClass);

  // V850 FPU feature - use FPR class for f32 and DPR class for f64
  // FPR uses same physical registers as GPR but typed as f32.
  // DPR uses even/odd GPR pairs (D6=(R6,R7), D8=(R8,R9), etc.) typed as f64.
  if (STI.hasV850FPU()) {
    addRegisterClass(MVT::f32, &V850::FPRRegClass);
    addRegisterClass(MVT::f64, &V850::DPRRegClass);
    LLVM_DEBUG(dbgs() << "V850: addRegisterClass f64 DPR done, RegClass="
                      << (void *)getRegClassFor(MVT::f64) << "\n");
  }

  // Compute derived properties from the register classes
  computeRegisterProperties(STI.getRegisterInfo());
  LLVM_DEBUG(dbgs() << "V850: after computeRegisterProperties, f64 isTypeLegal="
                    << isTypeLegal(MVT::f64) << "\n");

  // Set scheduling preference
  setSchedulingPreference(Sched::RegPressure);

  // Set up the stack pointer register
  setStackPointerRegisterToSaveRestore(V850::SP);

  // Boolean values
  setBooleanContents(ZeroOrOneBooleanContent);

  // Set up operation actions

  // Division and remainder
  if (STI.hasV850E1()) {
    // V850E1+ has hardware DIV/DIVU instructions
    setOperationAction(ISD::SDIV, MVT::i32, Custom);
    setOperationAction(ISD::UDIV, MVT::i32, Custom);
    setOperationAction(ISD::SREM, MVT::i32, Custom);
    setOperationAction(ISD::UREM, MVT::i32, Custom);
    setOperationAction(ISD::SDIVREM, MVT::i32, Custom);
    setOperationAction(ISD::UDIVREM, MVT::i32, Custom);
  } else {
    // Base V850 uses library calls
    setOperationAction(ISD::SDIV, MVT::i32, Expand);
    setOperationAction(ISD::UDIV, MVT::i32, Expand);
    setOperationAction(ISD::SREM, MVT::i32, Expand);
    setOperationAction(ISD::UREM, MVT::i32, Expand);
    setOperationAction(ISD::SDIVREM, MVT::i32, Expand);
    setOperationAction(ISD::UDIVREM, MVT::i32, Expand);
  }

  // Multiplication
  if (STI.hasV850E1()) {
    // V850E1+ has hardware MUL/MULU instructions
    setOperationAction(ISD::MUL, MVT::i32, Custom);
    setOperationAction(ISD::MULHS, MVT::i32, Custom);
    setOperationAction(ISD::MULHU, MVT::i32, Custom);
    setOperationAction(ISD::SMUL_LOHI, MVT::i32, Expand);
    setOperationAction(ISD::UMUL_LOHI, MVT::i32, Expand);
  } else {
    // Base V850 has MULH (16x16 multiply) but no 32x32 MUL.
    // Use Custom to let LowerMUL detect 16-bit patterns and use MULH,
    // otherwise fall back to library call.
    setOperationAction(ISD::MUL, MVT::i32, Custom);
    setOperationAction(ISD::MULHS, MVT::i32, Expand);
    setOperationAction(ISD::MULHU, MVT::i32, Expand);
    setOperationAction(ISD::SMUL_LOHI, MVT::i32, Expand);
    setOperationAction(ISD::UMUL_LOHI, MVT::i32, Expand);
  }

  // Rotates - RH850G3M+ has native ROTL instruction
  if (Subtarget.hasRH850G3M()) {
    setOperationAction(ISD::ROTL, MVT::i32, Legal);
    // ROTR is implemented as ROTL with (32 - amount)
    setOperationAction(ISD::ROTR, MVT::i32, Expand);
  } else {
    setOperationAction(ISD::ROTL, MVT::i32, Expand);
    setOperationAction(ISD::ROTR, MVT::i32, Expand);
  }

  // Bit counting
  // V850E2+ has SCH1L/SCH1R for ctlz/cttz, SCH0L/SCH0R for ctlz(not)/cttz(not)
  if (STI.hasV850E2()) {
    setOperationAction(ISD::CTLZ, MVT::i32, Legal);
    setOperationAction(ISD::CTTZ, MVT::i32, Legal);
  } else {
    setOperationAction(ISD::CTLZ, MVT::i32, Expand);
    setOperationAction(ISD::CTTZ, MVT::i32, Expand);
  }
  setOperationAction(ISD::CTPOP, MVT::i32, Expand);
  setOperationAction(ISD::BSWAP, MVT::i32, Legal); // V850 has BSW instruction
  setOperationAction(ISD::BITREVERSE, MVT::i32, Expand);

  // Saturating arithmetic - V850 has SATADD/SATSUB instructions
  // These are signed saturating operations (saturate to INT_MIN/INT_MAX)
  setOperationAction(ISD::SADDSAT, MVT::i32, Legal);
  setOperationAction(ISD::SSUBSAT, MVT::i32, Legal);
  // Unsigned saturating not supported in hardware
  setOperationAction(ISD::UADDSAT, MVT::i32, Expand);
  setOperationAction(ISD::USUBSAT, MVT::i32, Expand);

  // Sign extension in register - V850E1+ has SXB and SXH instructions
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i1, Expand);
  if (STI.hasV850E1()) {
    // V850E1+ has SXB (sign extend byte) and SXH (sign extend halfword)
    setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i8, Legal);
    setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i16, Legal);
  } else {
    // Base V850 must expand to shifts
    setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i8, Expand);
    setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i16, Expand);
  }

  // Expand SELECT to SELECT_CC
  setOperationAction(ISD::SELECT, MVT::i32, Expand);
  setOperationAction(ISD::SELECT_CC, MVT::i32, Custom);

  // Custom lowering for branch conditions
  setOperationAction(ISD::BR_CC, MVT::i32, Custom);
  setOperationAction(ISD::BRCOND, MVT::Other, Expand);

  // Global addresses and constant pools
  setOperationAction(ISD::GlobalAddress, MVT::i32, Custom);
  setOperationAction(ISD::ExternalSymbol, MVT::i32, Custom);
  setOperationAction(ISD::BlockAddress, MVT::i32, Custom);
  setOperationAction(ISD::ConstantPool, MVT::i32, Custom);

  // Jump table - V850E1+ has SWITCH instruction for table-driven branching
  if (STI.hasV850E1()) {
    setOperationAction(ISD::BR_JT, MVT::Other, Custom);
  } else {
    setOperationAction(ISD::BR_JT, MVT::Other, Expand);
  }

  // VAARG support - VASTART needs custom lowering to set up va_list
  setOperationAction(ISD::VASTART, MVT::Other, Custom);
  setOperationAction(ISD::VAARG, MVT::Other, Expand);
  setOperationAction(ISD::VAEND, MVT::Other, Expand);
  setOperationAction(ISD::VACOPY, MVT::Other, Expand);

  // Dynamic stack allocation
  setOperationAction(ISD::DYNAMIC_STACKALLOC, MVT::i32, Expand);
  setOperationAction(ISD::STACKSAVE, MVT::Other, Expand);
  setOperationAction(ISD::STACKRESTORE, MVT::Other, Expand);

  // Frame/return address
  setOperationAction(ISD::FRAMEADDR, MVT::i32, Custom);
  setOperationAction(ISD::RETURNADDR, MVT::i32, Custom);

  // Atomics - V850E2M has CAXI instruction for 32-bit compare-and-swap
  if (STI.hasV850E2M()) {
    setMaxAtomicSizeInBitsSupported(32);
    setMinCmpXchgSizeInBits(32);
    // V850E2M has SYNCP/SYNCM/SYNCE barrier instructions
    setOperationAction(ISD::ATOMIC_FENCE, MVT::Other, Custom);
    // Atomic loads/stores are custom-lowered to regular loads/stores.
    // V850 is single-core in-order, so aligned loads/stores are inherently
    // atomic. Memory ordering is handled by fences (SYNCP) inserted by
    // shouldInsertFencesForAtomic().
    setOperationAction(ISD::ATOMIC_LOAD, MVT::i32, Custom);
    setOperationAction(ISD::ATOMIC_STORE, MVT::i32, Custom);
  } else {
    setMaxAtomicSizeInBitsSupported(0);
  }

  // Multi-precision arithmetic - V850E2+ has ADF/SBF for efficient 64-bit ops
  // ADF: add with flag (reg3 = reg2 + reg1 + (cond ? 1 : 0))
  // SBF: subtract with flag (reg3 = reg2 - reg1 - (cond ? 1 : 0))
  // Using condition C (carry), this implements add/sub with carry
  if (STI.hasV850E2()) {
    setOperationAction(ISD::ADDC, MVT::i32, Legal);
    setOperationAction(ISD::ADDE, MVT::i32, Legal);
    setOperationAction(ISD::SUBC, MVT::i32, Legal);
    setOperationAction(ISD::SUBE, MVT::i32, Legal);
  }

  // Intrinsics - V850E1+ has register-based bit manipulation instructions
  if (STI.hasV850E1()) {
    setOperationAction(ISD::INTRINSIC_W_CHAIN, MVT::Other, Custom);
  }

  // Hardware loop intrinsics (RH850G3M+ LOOP instruction)
  // start_loop_iterations and loop_decrement_reg are INTRINSIC_W_CHAIN
  // (they have IntrNoDuplicate which adds a chain).
  // Note: INTRINSIC_W_CHAIN is already set to Custom for V850E1+ above,
  // and G3M implies E1, so no additional setOperationAction needed.

  // FPU operations when hardware FPU feature is present
  if (STI.hasV850FPU()) {
    // Single-precision floating-point operations - Legal
    // V850E2M has hardware support for these
    setOperationAction(ISD::FADD, MVT::f32, Legal);
    setOperationAction(ISD::FSUB, MVT::f32, Legal);
    setOperationAction(ISD::FMUL, MVT::f32, Legal);
    setOperationAction(ISD::FDIV, MVT::f32, Legal);
    setOperationAction(ISD::FABS, MVT::f32, Legal);
    setOperationAction(ISD::FNEG, MVT::f32, Legal);
    setOperationAction(ISD::FSQRT, MVT::f32, Legal);
    setOperationAction(ISD::FMINNUM, MVT::f32, Legal);
    setOperationAction(ISD::FMAXNUM, MVT::f32, Legal);

    // FMA operations - V850E2M has MADDF.S/MSUBF.S
    setOperationAction(ISD::FMA, MVT::f32, Legal);

    // Rounding operations - use library calls for now
    setOperationAction(ISD::FCEIL, MVT::f32, Expand);
    setOperationAction(ISD::FFLOOR, MVT::f32, Expand);
    setOperationAction(ISD::FTRUNC, MVT::f32, Expand);
    setOperationAction(ISD::FROUND, MVT::f32, Expand);

    // Conversions
    setOperationAction(ISD::SINT_TO_FP, MVT::i32, Legal);
    setOperationAction(ISD::UINT_TO_FP, MVT::i32, Legal);
    setOperationAction(ISD::FP_TO_SINT, MVT::i32, Legal);
    setOperationAction(ISD::FP_TO_UINT, MVT::i32, Legal);

    // FP comparisons - CMPF.S + TRFSR + SETF/CMOV/BR sequence
    // SETCC f32 is Legal (handled in ISel via CMPF.S + TRFSR + SETF)
    // SELECT_CC f32 and BR_CC f32 are Custom (lowered via V850ISD::FP_CMP)
    setOperationAction(ISD::SETCC, MVT::f32, Legal);
    setOperationAction(ISD::SELECT_CC, MVT::f32, Custom);
    setOperationAction(ISD::SELECT, MVT::f32, Expand);
    setOperationAction(ISD::BR_CC, MVT::f32, Custom);

    // Double-precision operations - Legal via hardware ADDF.D, SUBF.D, etc.
    setOperationAction(ISD::FADD, MVT::f64, Legal);
    setOperationAction(ISD::FSUB, MVT::f64, Legal);
    setOperationAction(ISD::FMUL, MVT::f64, Legal);
    setOperationAction(ISD::FDIV, MVT::f64, Legal);
    setOperationAction(ISD::FABS, MVT::f64, Legal);
    setOperationAction(ISD::FNEG, MVT::f64, Legal);
    setOperationAction(ISD::FSQRT, MVT::f64, Legal);
    setOperationAction(ISD::FMINNUM, MVT::f64, Legal);
    setOperationAction(ISD::FMAXNUM, MVT::f64, Legal);

    // f32 <-> f64 conversions - Legal via CVTF.DS / CVTF.SD
    setOperationAction(ISD::FP_EXTEND, MVT::f64, Legal);
    setOperationAction(ISD::FP_ROUND, MVT::f32, Legal);

    // Prevent LLVM from folding double constants into f32 constant-pool entries
    // with anyext-on-load. We have no single instruction for "load f32, extend
    // to f64"; instead Expand splits it into load<f32> + FP_EXTEND (CVTF.SD).
    setLoadExtAction(ISD::EXTLOAD, MVT::f64, MVT::f32, Expand);

    // f64 <-> i32 conversions - Legal via TRNCF.DW / CVTF.WD
    setOperationAction(ISD::FP_TO_SINT, MVT::f64, Legal);
    setOperationAction(ISD::FP_TO_UINT, MVT::f64, Legal);
    setOperationAction(ISD::SINT_TO_FP, MVT::f64, Legal);
    setOperationAction(ISD::UINT_TO_FP, MVT::f64, Legal);

    // f64 comparisons - CMPF.D + TRFSR + SETF/CMOV/BR
    setOperationAction(ISD::SETCC, MVT::f64, Legal);
    setOperationAction(ISD::SELECT_CC, MVT::f64, Custom);
    setOperationAction(ISD::SELECT, MVT::f64, Expand);
    setOperationAction(ISD::BR_CC, MVT::f64, Custom);

    // Truncating store f64 -> f32: expand to fpround + store<f32>
    setTruncStoreAction(MVT::f64, MVT::f32, Expand);

    // Bitcast between i32 and f32
    setOperationAction(ISD::BITCAST, MVT::i32, Legal);
    setOperationAction(ISD::BITCAST, MVT::f32, Legal);
  }

  // Set function alignment
  // V850 has both 16-bit and 32-bit instructions, so minimum is 2 bytes.
  // Preferred is 4 bytes for better instruction fetch of 32-bit instructions.
  // When optimizing for size (-Os/-Oz), the minimum alignment is used.
  setMinFunctionAlignment(Align(2));
  setPrefFunctionAlignment(Align(4));

  // Enable DAG combining for MAC pattern recognition (V850E2M+)
  // We check both ADD (for legacy pattern) and ADDE (when ADDC/ADDE are Legal)
  if (STI.hasV850E2M()) {
    setTargetDAGCombine(ISD::ADD);
    setTargetDAGCombine(ISD::ADDE);
  }

  // Enable DAG combining for bit manipulation (SET1/CLR1/NOT1)
  // These instructions are available on all V850 variants
  setTargetDAGCombine(ISD::STORE);

  // Enable DAG combining for SASF pattern matching (V850E1+)
  // SASF: (shl x, 1) | (setcc a, b, cond)
  if (STI.hasV850E1()) {
    setTargetDAGCombine(ISD::OR);
  }
}

SDValue V850TargetLowering::LowerOperation(SDValue Op,
                                           SelectionDAG &DAG) const {
  switch (Op.getOpcode()) {
  default:
    llvm_unreachable("unimplemented operation");
  case ISD::GlobalAddress:
    return LowerGlobalAddress(Op, DAG);
  case ISD::ExternalSymbol:
    return LowerExternalSymbol(Op, DAG);
  case ISD::BlockAddress:
    return LowerBlockAddress(Op, DAG);
  case ISD::ConstantPool:
    return LowerConstantPool(Op, DAG);
  case ISD::BR_CC:
    return LowerBR_CC(Op, DAG);
  case ISD::SELECT_CC:
    return LowerSELECT_CC(Op, DAG);
  case ISD::FRAMEADDR:
    return LowerFRAMEADDR(Op, DAG);
  case ISD::RETURNADDR:
    return LowerRETURNADDR(Op, DAG);
  case ISD::MUL:
    return LowerMUL(Op, DAG);
  case ISD::MULHS:
    return LowerMULHS(Op, DAG);
  case ISD::MULHU:
    return LowerMULHU(Op, DAG);
  case ISD::SDIV:
  case ISD::UDIV:
  case ISD::SREM:
  case ISD::UREM:
  case ISD::SDIVREM:
  case ISD::UDIVREM:
    return LowerDivRem(Op, DAG);
  case ISD::INTRINSIC_W_CHAIN:
    return LowerINTRINSIC_W_CHAIN(Op, DAG);
  case ISD::BR_JT:
    return LowerBR_JT(Op, DAG);
  case ISD::VASTART:
    return LowerVASTART(Op, DAG);
  case ISD::ATOMIC_FENCE:
    return LowerATOMIC_FENCE(Op, DAG);
  case ISD::ATOMIC_LOAD:
    return LowerATOMIC_LOAD(Op, DAG);
  case ISD::ATOMIC_STORE:
    return LowerATOMIC_STORE(Op, DAG);
  }
}

const char *V850TargetLowering::getTargetNodeName(unsigned Opcode) const {
  switch (static_cast<V850ISD::NodeType>(Opcode)) {
  case V850ISD::FIRST_NUMBER:
    break;
  case V850ISD::RET_GLUE:
    return "V850ISD::RET_GLUE";
  case V850ISD::CALL:
    return "V850ISD::CALL";
  case V850ISD::TAIL:
    return "V850ISD::TAIL";
  case V850ISD::WRAPPER:
    return "V850ISD::WRAPPER";
  case V850ISD::GPRel:
    return "V850ISD::GPRel";
  case V850ISD::BR_CC:
    return "V850ISD::BR_CC";
  case V850ISD::CMP:
    return "V850ISD::CMP";
  case V850ISD::SELECT_CC:
    return "V850ISD::SELECT_CC";
  case V850ISD::SMUL:
    return "V850ISD::SMUL";
  case V850ISD::UMUL:
    return "V850ISD::UMUL";
  case V850ISD::MULH16:
    return "V850ISD::MULH16";
  case V850ISD::SDIVREM:
    return "V850ISD::SDIVREM";
  case V850ISD::UDIVREM:
    return "V850ISD::UDIVREM";
  case V850ISD::SMAC:
    return "V850ISD::SMAC";
  case V850ISD::UMAC:
    return "V850ISD::UMAC";
  case V850ISD::SET1_MEM:
    return "V850ISD::SET1_MEM";
  case V850ISD::CLR1_MEM:
    return "V850ISD::CLR1_MEM";
  case V850ISD::NOT1_MEM:
    return "V850ISD::NOT1_MEM";
  case V850ISD::TST1_MEM:
    return "V850ISD::TST1_MEM";
  case V850ISD::BR_JT:
    return "V850ISD::BR_JT";
  case V850ISD::SASF:
    return "V850ISD::SASF";
  case V850ISD::FP_CMP:
    return "V850ISD::FP_CMP";
  }
  return nullptr;
}

SDValue V850TargetLowering::LowerGlobalAddress(SDValue Op,
                                               SelectionDAG &DAG) const {
  SDLoc DL(Op);
  EVT VT = Op.getValueType();
  const GlobalValue *GV = cast<GlobalAddressSDNode>(Op)->getGlobal();
  int64_t Offset = cast<GlobalAddressSDNode>(Op)->getOffset();

  // Check if this global should use GP-relative addressing (small data section)
  const GlobalObject *GO = GV->getAliaseeObject();
  const TargetMachine &TM = DAG.getTarget();
  const V850ELFTargetObjectFile *TLOF =
      static_cast<const V850ELFTargetObjectFile *>(TM.getObjFileLowering());

  if (GO && TLOF->IsGlobalInSmallSection(GO, TM)) {
    // Use GP-relative addressing: add GP, %gp_rel(sym)
    SDValue GPRelSym =
        DAG.getTargetGlobalAddress(GV, DL, VT, Offset, V850II::MO_GPREL);
    SDValue GPRel = DAG.getNode(V850ISD::GPRel, DL, VT, GPRelSym);
    SDValue GP = DAG.getRegister(V850::GP, VT);
    return DAG.getNode(ISD::ADD, DL, VT, GP, GPRel);
  }

  // Default: use absolute addressing with WRAPPER
  SDValue GA = DAG.getTargetGlobalAddress(GV, DL, VT, Offset);
  return DAG.getNode(V850ISD::WRAPPER, DL, VT, GA);
}

SDValue V850TargetLowering::LowerExternalSymbol(SDValue Op,
                                                SelectionDAG &DAG) const {
  SDLoc DL(Op);
  EVT VT = Op.getValueType();
  const char *Sym = cast<ExternalSymbolSDNode>(Op)->getSymbol();

  SDValue ES = DAG.getTargetExternalSymbol(Sym, VT);
  return DAG.getNode(V850ISD::WRAPPER, DL, VT, ES);
}

SDValue V850TargetLowering::LowerBlockAddress(SDValue Op,
                                              SelectionDAG &DAG) const {
  SDLoc DL(Op);
  EVT VT = Op.getValueType();
  const BlockAddress *BA = cast<BlockAddressSDNode>(Op)->getBlockAddress();

  SDValue Result = DAG.getTargetBlockAddress(BA, VT);
  return DAG.getNode(V850ISD::WRAPPER, DL, VT, Result);
}

SDValue V850TargetLowering::LowerConstantPool(SDValue Op,
                                              SelectionDAG &DAG) const {
  SDLoc DL(Op);
  EVT VT = Op.getValueType();
  ConstantPoolSDNode *CP = cast<ConstantPoolSDNode>(Op);

  SDValue Result;
  if (CP->isMachineConstantPoolEntry())
    Result = DAG.getTargetConstantPool(CP->getMachineCPVal(), VT,
                                       CP->getAlign(), CP->getOffset());
  else
    Result = DAG.getTargetConstantPool(CP->getConstVal(), VT, CP->getAlign(),
                                       CP->getOffset());

  return DAG.getNode(V850ISD::WRAPPER, DL, VT, Result);
}

/// Map ISD::CondCode for floating-point to V850 CMPF fcond value.
/// Returns {fcond, needSwap, needNegate}.
/// - fcond: V850 CMPF condition code (0-15)
/// - needSwap: swap LHS/RHS operands before CMPF
/// - needNegate: negate result (use NZ instead of Z after TRFSR)
///
/// V850 CMPF fcond values:
///   0 (F)    - False              1 (UN)   - Unordered
///   2 (EQ)   - Equal              3 (UEQ)  - Unordered or Equal
///   4 (OLT)  - Ordered Less Than  5 (ULT)  - Unordered or Less Than
///   6 (OLE)  - Ordered Less/Equal 7 (ULE)  - Unordered or Less/Equal
struct FPCondResult {
  unsigned FCond;
  bool NeedSwap;
  bool NeedNegate;
};

static FPCondResult getFPCondCode(ISD::CondCode CC) {
  switch (CC) {
  default:
    llvm_unreachable("Unknown FP condition code");
  case ISD::SETFALSE:
  case ISD::SETFALSE2:
    return {0, false, false}; // F - always false
  case ISD::SETOEQ:
    return {2, false, false}; // EQ
  case ISD::SETOGT:
    return {4, true, false}; // OLT with swap (LHS > RHS ≡ RHS < LHS)
  case ISD::SETOGE:
    return {6, true, false}; // OLE with swap
  case ISD::SETOLT:
    return {4, false, false}; // OLT
  case ISD::SETOLE:
    return {6, false, false}; // OLE
  case ISD::SETONE:
    return {3, false,
            true}; // !UEQ (not unordered-or-equal = ordered not-equal)
  case ISD::SETO:
    return {1, false, true}; // !UN (not unordered = ordered)
  case ISD::SETUO:
    return {1, false, false}; // UN
  case ISD::SETUEQ:
    return {3, false, false}; // UEQ
  case ISD::SETUGT:
    return {5, true, false}; // ULT with swap
  case ISD::SETUGE:
    return {7, true, false}; // ULE with swap
  case ISD::SETULT:
    return {5, false, false}; // ULT
  case ISD::SETULE:
    return {7, false, false}; // ULE
  case ISD::SETUNE:
    return {2, false, true}; // !EQ
  case ISD::SETTRUE:
  case ISD::SETTRUE2:
    return {0, false, true}; // !F = always true
  // Handle generic (non-ordered-specific) codes as ordered equivalents
  case ISD::SETEQ:
    return {2, false, false}; // EQ (same as SETOEQ)
  case ISD::SETNE:
    return {2, false, true}; // !EQ (same as SETUNE)
  case ISD::SETLT:
    return {4, false, false}; // OLT
  case ISD::SETLE:
    return {6, false, false}; // OLE
  case ISD::SETGT:
    return {4, true, false}; // OLT with swap
  case ISD::SETGE:
    return {6, true, false}; // OLE with swap
  }
}

SDValue V850TargetLowering::LowerBR_CC(SDValue Op, SelectionDAG &DAG) const {
  SDValue Chain = Op.getOperand(0);
  ISD::CondCode CC = cast<CondCodeSDNode>(Op.getOperand(1))->get();
  SDValue LHS = Op.getOperand(2);
  SDValue RHS = Op.getOperand(3);
  SDValue Dest = Op.getOperand(4);
  SDLoc DL(Op);

  SDValue Cmp;
  ISD::CondCode BrCC = CC;

  EVT LVT = LHS.getValueType();
  if (LVT == MVT::f32 || LVT == MVT::f64) {
    // Floating-point comparison: CMPF.S/D + TRFSR → PSW.Z
    FPCondResult FPC = getFPCondCode(CC);
    if (FPC.NeedSwap)
      std::swap(LHS, RHS);
    Cmp = DAG.getNode(V850ISD::FP_CMP, DL, MVT::Glue,
                      DAG.getConstant(FPC.FCond, DL, MVT::i32), LHS, RHS);
    // After TRFSR: Z=1 if comparison true, Z=0 if false
    // Use SETEQ (→ BZ) for true, SETNE (→ BNZ) for negated
    BrCC = FPC.NeedNegate ? ISD::SETNE : ISD::SETEQ;
  } else {
    // Integer comparison
    Cmp = DAG.getNode(V850ISD::CMP, DL, MVT::Glue, LHS, RHS);
  }

  return DAG.getNode(V850ISD::BR_CC, DL, Op.getValueType(), Chain, Dest,
                     DAG.getConstant(BrCC, DL, MVT::i32), Cmp);
}

SDValue V850TargetLowering::LowerSELECT_CC(SDValue Op,
                                           SelectionDAG &DAG) const {
  SDValue LHS = Op.getOperand(0);
  SDValue RHS = Op.getOperand(1);
  SDValue TrueV = Op.getOperand(2);
  SDValue FalseV = Op.getOperand(3);
  ISD::CondCode CC = cast<CondCodeSDNode>(Op.getOperand(4))->get();
  SDLoc DL(Op);
  EVT ResultVT = Op.getValueType();

  SDValue Cmp;
  ISD::CondCode SelCC = CC;

  EVT LVTS = LHS.getValueType();
  if (LVTS == MVT::f32 || LVTS == MVT::f64) {
    // Floating-point comparison: CMPF.S/D + TRFSR → PSW.Z
    FPCondResult FPC = getFPCondCode(CC);
    if (FPC.NeedSwap)
      std::swap(LHS, RHS);
    Cmp = DAG.getNode(V850ISD::FP_CMP, DL, MVT::Glue,
                      DAG.getConstant(FPC.FCond, DL, MVT::i32), LHS, RHS);
    // After TRFSR: Z=1 if comparison true → use SETEQ for CMOV condition
    SelCC = FPC.NeedNegate ? ISD::SETNE : ISD::SETEQ;
  } else {
    // Integer comparison
    Cmp = DAG.getNode(V850ISD::CMP, DL, MVT::Glue, LHS, RHS);
  }

  // For f32 result, bitcast to i32 for CMOV, then bitcast back
  if (ResultVT == MVT::f32) {
    TrueV = DAG.getNode(ISD::BITCAST, DL, MVT::i32, TrueV);
    FalseV = DAG.getNode(ISD::BITCAST, DL, MVT::i32, FalseV);
    SDValue Sel = DAG.getNode(V850ISD::SELECT_CC, DL, MVT::i32, TrueV, FalseV,
                              DAG.getConstant(SelCC, DL, MVT::i32), Cmp);
    return DAG.getNode(ISD::BITCAST, DL, MVT::f32, Sel);
  }

  // For f64 result: emit V850ISD::SELECT_CC with f64 type.
  // V850 has no f64 CMOV instruction; the DAGToDAG ISel handles this by
  // splitting the DPR register into sub_lo/sub_hi GPR halves via
  // EXTRACT_SUBREG, applying two CMOVr (one per half), then INSERT_SUBREG.
  return DAG.getNode(V850ISD::SELECT_CC, DL, ResultVT, TrueV, FalseV,
                     DAG.getConstant(SelCC, DL, MVT::i32), Cmp);
}

// Helper to check if a value is sign-extended from i16
// Returns true if the value effectively contains a sign-extended i16
static bool isSExtFromI16(SDValue V) {
  // Case 1: sign_extend_inreg (explicit sign extension of bits)
  if (V.getOpcode() == ISD::SIGN_EXTEND_INREG) {
    VTSDNode *VTN = cast<VTSDNode>(V.getOperand(1));
    return VTN->getVT() == MVT::i16;
  }
  // Case 2: sign_extend from i16 (before type legalization)
  if (V.getOpcode() == ISD::SIGN_EXTEND &&
      V.getOperand(0).getValueType() == MVT::i16) {
    return true;
  }
  // Case 3: sign-extending load from i16 (after type legalization)
  if (auto *Load = dyn_cast<LoadSDNode>(V)) {
    if (Load->getExtensionType() == ISD::SEXTLOAD &&
        Load->getMemoryVT() == MVT::i16) {
      return true;
    }
  }
  return false;
}

SDValue V850TargetLowering::LowerMUL(SDValue Op, SelectionDAG &DAG) const {
  // V850's MUL instruction produces a 64-bit result in two registers.
  // For simple 32-bit multiply, we use V850ISD::SMUL and take only the low
  // part.
  SDLoc DL(Op);
  SDValue LHS = Op.getOperand(0);
  SDValue RHS = Op.getOperand(1);

  // Check if both operands are sign-extended from i16.
  // In this case, use V850ISD::MULH16 which maps to the MULH instruction
  // (16x16 -> 32 bit multiply, more efficient than full 32x32 MUL)
  // MULH uses only the lower 16 bits of each operand, so we can pass
  // the i32 values directly.
  // MULH is available on all V850 variants.
  if (isSExtFromI16(LHS) && isSExtFromI16(RHS)) {
    return DAG.getNode(V850ISD::MULH16, DL, MVT::i32, LHS, RHS);
  }

  // V850E1+ has hardware MUL instruction. For base V850, return empty SDValue
  // to trigger expansion to library call.
  if (!Subtarget.hasV850E1()) {
    return SDValue();
  }

  // V850ISD::SMUL returns (low, high)
  SDValue MulLoHi = DAG.getNode(V850ISD::SMUL, DL,
                                DAG.getVTList(MVT::i32, MVT::i32), LHS, RHS);
  return MulLoHi.getValue(0); // Return the low 32 bits
}

SDValue V850TargetLowering::LowerMULHS(SDValue Op, SelectionDAG &DAG) const {
  // MULHS needs the high 32 bits of signed multiply
  SDLoc DL(Op);
  SDValue LHS = Op.getOperand(0);
  SDValue RHS = Op.getOperand(1);

  // V850ISD::SMUL returns (low, high)
  SDValue MulLoHi = DAG.getNode(V850ISD::SMUL, DL,
                                DAG.getVTList(MVT::i32, MVT::i32), LHS, RHS);
  return MulLoHi.getValue(1); // Return the high 32 bits
}

SDValue V850TargetLowering::LowerMULHU(SDValue Op, SelectionDAG &DAG) const {
  // MULHU needs the high 32 bits of unsigned multiply
  SDLoc DL(Op);
  SDValue LHS = Op.getOperand(0);
  SDValue RHS = Op.getOperand(1);

  // V850ISD::UMUL returns (low, high)
  SDValue MulLoHi = DAG.getNode(V850ISD::UMUL, DL,
                                DAG.getVTList(MVT::i32, MVT::i32), LHS, RHS);
  return MulLoHi.getValue(1); // Return the high 32 bits
}

SDValue V850TargetLowering::LowerDivRem(SDValue Op, SelectionDAG &DAG) const {
  // V850's DIV/DIVU instructions produce both quotient and remainder.
  // Convert SDIV/UDIV/SREM/UREM to V850ISD::SDIVREM/UDIVREM and extract the
  // needed part.
  SDLoc DL(Op);
  unsigned Opcode = Op.getOpcode();
  SDValue LHS = Op.getOperand(0);
  SDValue RHS = Op.getOperand(1);

  bool IsSigned =
      (Opcode == ISD::SDIV || Opcode == ISD::SREM || Opcode == ISD::SDIVREM);
  bool WantsQuotient = (Opcode == ISD::SDIV || Opcode == ISD::UDIV);
  bool WantsRemainder = (Opcode == ISD::SREM || Opcode == ISD::UREM);

  // V850ISD::SDIVREM and UDIVREM return (quotient, remainder)
  unsigned DivRemOpc = IsSigned ? V850ISD::SDIVREM : V850ISD::UDIVREM;
  SDValue DivRem =
      DAG.getNode(DivRemOpc, DL, DAG.getVTList(MVT::i32, MVT::i32), LHS, RHS);

  // For SDIVREM/UDIVREM, we need to return both values
  if (Opcode == ISD::SDIVREM || Opcode == ISD::UDIVREM)
    return DivRem;

  // Return quotient (result 0) or remainder (result 1)
  return DivRem.getValue(WantsRemainder ? 1 : 0);
}

SDValue V850TargetLowering::LowerRETURNADDR(SDValue Op,
                                            SelectionDAG &DAG) const {
  MachineFrameInfo &MFI = DAG.getMachineFunction().getFrameInfo();
  MFI.setReturnAddressIsTaken(true);

  if (cast<ConstantSDNode>(Op.getOperand(0))->getZExtValue() != 0)
    return SDValue();

  // Return LP (r31)
  SDLoc DL(Op);
  return DAG.getCopyFromReg(DAG.getEntryNode(), DL, V850::LP, MVT::i32);
}

SDValue V850TargetLowering::LowerFRAMEADDR(SDValue Op,
                                           SelectionDAG &DAG) const {
  MachineFrameInfo &MFI = DAG.getMachineFunction().getFrameInfo();
  MFI.setFrameAddressIsTaken(true);

  if (cast<ConstantSDNode>(Op.getOperand(0))->getZExtValue() != 0)
    return SDValue();

  SDLoc DL(Op);
  // Use R29 as frame pointer
  return DAG.getCopyFromReg(DAG.getEntryNode(), DL, V850::R29, MVT::i32);
}

Register
V850TargetLowering::getRegisterByName(const char *RegName, LLT VT,
                                      const MachineFunction &MF) const {
  Register Reg = StringSwitch<Register>(RegName)
                     .Case("sp", V850::SP)
                     .Case("r3", V850::SP)
                     .Case("gp", V850::GP)
                     .Case("r4", V850::GP)
                     .Case("tp", V850::TP)
                     .Case("r5", V850::TP)
                     .Case("ep", V850::EP)
                     .Case("r30", V850::EP)
                     .Case("lp", V850::LP)
                     .Case("r31", V850::LP)
                     .Default(Register());

  if (Reg)
    return Reg;

  report_fatal_error(
      Twine("Invalid register name \"" + StringRef(RegName) + "\"."));
}

//===----------------------------------------------------------------------===//
//                      Intrinsic Lowering
//===----------------------------------------------------------------------===//

SDValue V850TargetLowering::LowerINTRINSIC_W_CHAIN(SDValue Op,
                                                   SelectionDAG &DAG) const {
  SDLoc DL(Op);
  unsigned IntNo = Op.getConstantOperandVal(1);

  switch (IntNo) {
  default:
    return SDValue(); // Don't custom lower this intrinsic
  case Intrinsic::start_loop_iterations: {
    // start_loop_iterations(n) -> n (identity, count goes to GPR via phi)
    // Returns: (i32 result, chain)
    SDValue Chain = Op.getOperand(0);
    SDValue Count = Op.getOperand(2); // Operand 1 is intrinsic ID, 2 is the arg
    return DAG.getMergeValues({Count, Chain}, DL);
  }
  case Intrinsic::loop_decrement_reg: {
    // loop_decrement_reg(counter, decrement) -> counter - decrement
    // The result feeds back through a phi as the new counter value.
    // V850HardwareLoopPass converts add -1 + cmp 0 + bnz into LOOP.
    SDValue Chain = Op.getOperand(0);
    SDValue Counter = Op.getOperand(2); // operand 1 is intrinsic ID
    SDValue Decrement = Op.getOperand(3);
    SDValue Sub = DAG.getNode(ISD::SUB, DL, MVT::i32, Counter, Decrement);
    return DAG.getMergeValues({Sub, Chain}, DL);
  }
  case Intrinsic::v850_tst1: {
    // TST1 - Test bit in memory
    // Returns 1 if bit was 0 (Z flag set), 0 otherwise
    SDValue Chain = Op.getOperand(0);
    SDValue Addr = Op.getOperand(2);
    SDValue Bit = Op.getOperand(3);

    // Create TST1_MEM node: (result, chain) = TST1_MEM chain, addr, bit
    SDVTList VTs = DAG.getVTList(MVT::i32, MVT::Other);
    SDValue Ops[] = {Chain, Addr, Bit};
    return DAG.getNode(V850ISD::TST1_MEM, DL, VTs, Ops);
  }
  }
}

//===----------------------------------------------------------------------===//
//                      Jump Table Lowering (V850E1+)
//===----------------------------------------------------------------------===//

SDValue V850TargetLowering::LowerBR_JT(SDValue Op, SelectionDAG &DAG) const {
  SDValue Chain = Op.getOperand(0);
  SDValue Table = Op.getOperand(1);
  SDValue Index = Op.getOperand(2);
  SDLoc DL(Op);

  // Get the jump table index
  JumpTableSDNode *JT = cast<JumpTableSDNode>(Table);
  SDValue JTI = DAG.getTargetJumpTable(JT->getIndex(), MVT::i32);

  // Create V850ISD::BR_JT node: chain = BR_JT chain, index, jumptable
  // The SWITCH instruction will be generated from this node
  return DAG.getNode(V850ISD::BR_JT, DL, MVT::Other, Chain, Index, JTI);
}

unsigned V850TargetLowering::getJumpTableEncoding() const {
  // V850E1+ uses inline jump tables with SWITCH instruction
  // Each entry is a signed 16-bit offset (halfword) from the table base
  if (Subtarget.hasV850E1())
    return MachineJumpTableInfo::EK_Inline;

  // Base V850 uses standard block addresses
  return MachineJumpTableInfo::EK_BlockAddress;
}

//===----------------------------------------------------------------------===//
//                      Varargs Support
//===----------------------------------------------------------------------===//

SDValue V850TargetLowering::LowerVASTART(SDValue Op, SelectionDAG &DAG) const {
  MachineFunction &MF = DAG.getMachineFunction();
  V850MachineFunctionInfo *FuncInfo = MF.getInfo<V850MachineFunctionInfo>();

  SDLoc DL(Op);
  SDValue FI = DAG.getFrameIndex(FuncInfo->getVarArgsFrameIndex(),
                                 getPointerTy(MF.getDataLayout()));

  // vastart just stores the address of the VarArgsFrameIndex slot into the
  // memory location argument (the va_list pointer).
  const Value *SV = cast<SrcValueSDNode>(Op.getOperand(2))->getValue();
  return DAG.getStore(Op.getOperand(0), DL, FI, Op.getOperand(1),
                      MachinePointerInfo(SV));
}

SDValue V850TargetLowering::LowerATOMIC_FENCE(SDValue Op,
                                              SelectionDAG &DAG) const {
  SDLoc DL(Op);
  AtomicOrdering Ord = static_cast<AtomicOrdering>(Op.getConstantOperandVal(1));

  // For V850E2M+, use SYNCP as the hardware memory barrier.
  // SYNCP is the strongest barrier (full pipeline synchronization).
  // For weaker orderings we could use SYNCM or SYNCE, but SYNCP is always safe.
  if (Ord != AtomicOrdering::NotAtomic) {
    return SDValue(
        DAG.getMachineNode(V850::SYNCP, DL, MVT::Other, Op.getOperand(0)), 0);
  }

  // For NotAtomic, just return the chain (compiler fence only).
  return Op.getOperand(0);
}

SDValue V850TargetLowering::LowerATOMIC_LOAD(SDValue Op,
                                             SelectionDAG &DAG) const {
  auto *Node = cast<AtomicSDNode>(Op.getNode());
  SDLoc DL(Op);

  // V850 is single-core in-order, so aligned loads are inherently atomic.
  // Convert atomic load to a regular load. Memory ordering is handled by
  // fences inserted by shouldInsertFencesForAtomic().
  assert(Node->getMemoryVT() == MVT::i32 && "Expected i32 atomic load");
  return DAG.getLoad(MVT::i32, DL, Node->getChain(), Node->getBasePtr(),
                     Node->getMemOperand());
}

SDValue V850TargetLowering::LowerATOMIC_STORE(SDValue Op,
                                              SelectionDAG &DAG) const {
  auto *Node = cast<AtomicSDNode>(Op.getNode());
  SDLoc DL(Op);

  // V850 is single-core in-order, so aligned stores are inherently atomic.
  // Convert atomic store to a regular store. Memory ordering is handled by
  // fences inserted by shouldInsertFencesForAtomic().
  assert(Node->getMemoryVT() == MVT::i32 && "Expected i32 atomic store");
  return DAG.getStore(Node->getChain(), DL, Node->getVal(), Node->getBasePtr(),
                      Node->getMemOperand());
}

bool V850TargetLowering::shouldInsertFencesForAtomic(
    const Instruction *I) const {
  // V850 is single-core in-order. Atomic loads/stores are regular loads/stores
  // with fences for ordering. Insert fences around atomic load/store to handle
  // acquire/release/seq_cst ordering, and reduce the atomic to monotonic.
  if (isa<LoadInst>(I) || isa<StoreInst>(I))
    return true;
  return false;
}

//===----------------------------------------------------------------------===//
//                      Calling Convention Implementation
//===----------------------------------------------------------------------===//

SDValue V850TargetLowering::LowerFormalArguments(
    SDValue Chain, CallingConv::ID CallConv, bool isVarArg,
    const SmallVectorImpl<ISD::InputArg> &Ins, const SDLoc &dl,
    SelectionDAG &DAG, SmallVectorImpl<SDValue> &InVals) const {

  MachineFunction &MF = DAG.getMachineFunction();
  MachineFrameInfo &MFI = MF.getFrameInfo();
  MachineRegisterInfo &RegInfo = MF.getRegInfo();

  // Mark SP as live-in so that ADJCALLSTACKDOWN's implicit use of $sp has a
  // reaching definition in functions that make calls with stack arguments.
  MF.front().addLiveIn(V850::SP);

  // Assign locations to all of the incoming arguments
  SmallVector<CCValAssign, 16> ArgLocs;
  CCState CCInfo(CallConv, isVarArg, MF, ArgLocs, *DAG.getContext());
  CCInfo.AnalyzeFormalArguments(Ins, CC_V850);

  for (unsigned i = 0, e = ArgLocs.size(); i != e; ++i) {
    CCValAssign &VA = ArgLocs[i];
    SDValue ArgValue;

    if (VA.isRegLoc()) {
      // Argument passed in register
      EVT RegVT = VA.getLocVT();
      const TargetRegisterClass *RC;
      if (RegVT == MVT::f64)
        RC = &V850::DPRRegClass;
      else if (RegVT == MVT::f32)
        RC = &V850::FPRRegClass;
      else
        RC = &V850::GPRRegClass;
      Register VReg = RegInfo.createVirtualRegister(RC);
      RegInfo.addLiveIn(VA.getLocReg(), VReg);
      ArgValue = DAG.getCopyFromReg(Chain, dl, VReg, RegVT);

      // Handle type promotion if needed
      if (VA.getLocInfo() == CCValAssign::SExt)
        ArgValue = DAG.getNode(ISD::AssertSext, dl, RegVT, ArgValue,
                               DAG.getValueType(VA.getValVT()));
      else if (VA.getLocInfo() == CCValAssign::ZExt)
        ArgValue = DAG.getNode(ISD::AssertZext, dl, RegVT, ArgValue,
                               DAG.getValueType(VA.getValVT()));

      if (VA.getLocInfo() != CCValAssign::Full)
        ArgValue = DAG.getNode(ISD::TRUNCATE, dl, VA.getValVT(), ArgValue);
    } else {
      // Argument passed on stack
      assert(VA.isMemLoc());
      int FI = MFI.CreateFixedObject(VA.getLocVT().getSizeInBits() / 8,
                                     VA.getLocMemOffset(), true);
      SDValue FIN = DAG.getFrameIndex(FI, MVT::i32);
      ArgValue = DAG.getLoad(VA.getLocVT(), dl, Chain, FIN,
                             MachinePointerInfo::getFixedStack(MF, FI));
    }

    InVals.push_back(ArgValue);
  }

  // If the function takes variable number of arguments, make a frame index for
  // the start of the first vararg value... for expansion of llvm.va_start.
  if (isVarArg) {
    V850MachineFunctionInfo *FuncInfo = MF.getInfo<V850MachineFunctionInfo>();
    unsigned StackSize = CCInfo.getStackSize();
    // Create a fixed stack object for the varargs area.
    // This is the location after all fixed arguments on the stack.
    int VarArgsFrameIndex = MFI.CreateFixedObject(4, StackSize, true);
    FuncInfo->setVarArgsFrameIndex(VarArgsFrameIndex);
  }

  return Chain;
}

SDValue V850TargetLowering::LowerCall(TargetLowering::CallLoweringInfo &CLI,
                                      SmallVectorImpl<SDValue> &InVals) const {
  SelectionDAG &DAG = CLI.DAG;
  SDLoc &DL = CLI.DL;
  SmallVectorImpl<ISD::OutputArg> &Outs = CLI.Outs;
  SmallVectorImpl<SDValue> &OutVals = CLI.OutVals;
  SmallVectorImpl<ISD::InputArg> &Ins = CLI.Ins;
  SDValue Chain = CLI.Chain;
  SDValue Callee = CLI.Callee;
  CallingConv::ID CallConv = CLI.CallConv;
  bool isVarArg = CLI.IsVarArg;
  bool &IsTailCall = CLI.IsTailCall;

  MachineFunction &MF = DAG.getMachineFunction();

  // Analyze operands of the call, assigning locations to each operand
  SmallVector<CCValAssign, 16> ArgLocs;
  CCState CCInfo(CallConv, isVarArg, MF, ArgLocs, *DAG.getContext());
  CCInfo.AnalyzeCallOperands(Outs, CC_V850);

  // Check if it's really possible to do a tail call.
  if (IsTailCall)
    IsTailCall = isEligibleForTailCallOptimization(CCInfo, CLI, MF, ArgLocs);

  if (IsTailCall)
    MF.getFrameInfo().setHasTailCall();
  else if (CLI.CB && CLI.CB->isMustTailCall())
    report_fatal_error("failed to perform tail call elimination on a call "
                       "site marked musttail");

  // Get the size of the outgoing arguments stack space
  unsigned NumBytes = CCInfo.getStackSize();

  if (!IsTailCall)
    Chain = DAG.getCALLSEQ_START(Chain, NumBytes, 0, DL);

  SmallVector<std::pair<Register, SDValue>, 4> RegsToPass;
  SmallVector<SDValue, 12> MemOpChains;

  // Walk the register/memloc assignments, inserting copies/loads
  for (unsigned i = 0, e = ArgLocs.size(); i != e; ++i) {
    CCValAssign &VA = ArgLocs[i];
    SDValue Arg = OutVals[i];

    // Promote the value if needed
    switch (VA.getLocInfo()) {
    default:
      llvm_unreachable("Unknown loc info!");
    case CCValAssign::Full:
      break;
    case CCValAssign::SExt:
      Arg = DAG.getNode(ISD::SIGN_EXTEND, DL, VA.getLocVT(), Arg);
      break;
    case CCValAssign::ZExt:
      Arg = DAG.getNode(ISD::ZERO_EXTEND, DL, VA.getLocVT(), Arg);
      break;
    case CCValAssign::AExt:
      Arg = DAG.getNode(ISD::ANY_EXTEND, DL, VA.getLocVT(), Arg);
      break;
    }

    if (VA.isRegLoc()) {
      RegsToPass.push_back(std::make_pair(VA.getLocReg(), Arg));
    } else {
      assert(VA.isMemLoc());
      assert(!IsTailCall && "Tail call not allowed if stack is used "
                            "for passing parameters");
      SDValue StackPtr = DAG.getCopyFromReg(Chain, DL, V850::SP, MVT::i32);
      SDValue PtrOff = DAG.getIntPtrConstant(VA.getLocMemOffset(), DL);
      PtrOff = DAG.getNode(ISD::ADD, DL, MVT::i32, StackPtr, PtrOff);
      MemOpChains.push_back(
          DAG.getStore(Chain, DL, Arg, PtrOff, MachinePointerInfo()));
    }
  }

  if (!MemOpChains.empty())
    Chain = DAG.getNode(ISD::TokenFactor, DL, MVT::Other, MemOpChains);

  // Build a sequence of copy-to-reg nodes chained together with glue
  SDValue InGlue;
  for (auto &Reg : RegsToPass) {
    Chain = DAG.getCopyToReg(Chain, DL, Reg.first, Reg.second, InGlue);
    InGlue = Chain.getValue(1);
  }

  // Handle global address or external symbol
  if (GlobalAddressSDNode *G = dyn_cast<GlobalAddressSDNode>(Callee))
    Callee = DAG.getTargetGlobalAddress(G->getGlobal(), DL, MVT::i32);
  else if (ExternalSymbolSDNode *E = dyn_cast<ExternalSymbolSDNode>(Callee))
    Callee = DAG.getTargetExternalSymbol(E->getSymbol(), MVT::i32);

  // Build the operands for the call node
  SmallVector<SDValue, 8> Ops;
  Ops.push_back(Chain);
  Ops.push_back(Callee);

  // Add argument registers to the end of the list
  for (auto &Reg : RegsToPass)
    Ops.push_back(DAG.getRegister(Reg.first, Reg.second.getValueType()));

  // For non-tail calls, add a register mask operand representing
  // call-preserved registers. Tail calls don't need this since they
  // end the function.
  if (!IsTailCall) {
    const TargetRegisterInfo *TRI = Subtarget.getRegisterInfo();
    const uint32_t *Mask = TRI->getCallPreservedMask(MF, CallConv);
    assert(Mask && "Missing call preserved mask for calling convention");
    Ops.push_back(DAG.getRegisterMask(Mask));
  }

  if (InGlue.getNode())
    Ops.push_back(InGlue);

  SDVTList NodeTys = DAG.getVTList(MVT::Other, MVT::Glue);

  if (IsTailCall) {
    // Tail call - emit TAIL node and return
    Chain = DAG.getNode(V850ISD::TAIL, DL, NodeTys, Ops);
    DAG.addNoMergeSiteInfo(Chain.getNode(), CLI.NoMerge);
    return Chain;
  }

  // Normal call
  Chain = DAG.getNode(V850ISD::CALL, DL, NodeTys, Ops);
  InGlue = Chain.getValue(1);

  Chain = DAG.getCALLSEQ_END(Chain, NumBytes, 0, InGlue, DL);
  InGlue = Chain.getValue(1);

  // Handle return values
  return LowerCallResult(Chain, InGlue, CallConv, isVarArg, Ins, DL, DAG,
                         InVals);
}

SDValue V850TargetLowering::LowerCallResult(
    SDValue Chain, SDValue InGlue, CallingConv::ID CallConv, bool isVarArg,
    const SmallVectorImpl<ISD::InputArg> &Ins, const SDLoc &dl,
    SelectionDAG &DAG, SmallVectorImpl<SDValue> &InVals) const {

  MachineFunction &MF = DAG.getMachineFunction();

  // Assign locations to each value returned by this call
  SmallVector<CCValAssign, 16> RVLocs;
  CCState CCInfo(CallConv, isVarArg, MF, RVLocs, *DAG.getContext());
  CCInfo.AnalyzeCallResult(Ins, RetCC_V850);

  // Copy all of the result registers out of their specified physreg
  for (unsigned i = 0; i != RVLocs.size(); ++i) {
    Chain = DAG.getCopyFromReg(Chain, dl, RVLocs[i].getLocReg(),
                               RVLocs[i].getValVT(), InGlue)
                .getValue(1);
    InGlue = Chain.getValue(2);
    InVals.push_back(Chain.getValue(0));
  }

  return Chain;
}

bool V850TargetLowering::CanLowerReturn(
    CallingConv::ID CallConv, MachineFunction &MF, bool IsVarArg,
    const SmallVectorImpl<ISD::OutputArg> &Outs, LLVMContext &Context,
    const Type *RetTy) const {
  SmallVector<CCValAssign, 16> RVLocs;
  CCState CCInfo(CallConv, IsVarArg, MF, RVLocs, Context);
  return CCInfo.CheckReturn(Outs, RetCC_V850);
}

SDValue
V850TargetLowering::LowerReturn(SDValue Chain, CallingConv::ID CallConv,
                                bool isVarArg,
                                const SmallVectorImpl<ISD::OutputArg> &Outs,
                                const SmallVectorImpl<SDValue> &OutVals,
                                const SDLoc &dl, SelectionDAG &DAG) const {
  MachineFunction &MF = DAG.getMachineFunction();

  // CCValAssign - represent the assignment of the return value to a location
  SmallVector<CCValAssign, 16> RVLocs;
  CCState CCInfo(CallConv, isVarArg, MF, RVLocs, *DAG.getContext());
  CCInfo.AnalyzeReturn(Outs, RetCC_V850);

  SDValue Glue;
  SmallVector<SDValue, 4> RetOps(1, Chain);

  // Copy the result values into the output registers
  for (unsigned i = 0; i != RVLocs.size(); ++i) {
    CCValAssign &VA = RVLocs[i];
    assert(VA.isRegLoc() && "Can only return in registers!");

    Chain = DAG.getCopyToReg(Chain, dl, VA.getLocReg(), OutVals[i], Glue);
    Glue = Chain.getValue(1);
    RetOps.push_back(DAG.getRegister(VA.getLocReg(), VA.getLocVT()));
  }

  RetOps[0] = Chain;

  if (Glue.getNode())
    RetOps.push_back(Glue);

  return DAG.getNode(V850ISD::RET_GLUE, dl, MVT::Other, RetOps);
}

//===----------------------------------------------------------------------===//
// DAG Combining
//===----------------------------------------------------------------------===//

/// Try to combine store(op(load(addr), const), addr) into SET1/CLR1/NOT1.
/// Pattern: store(or(load(addr), 2^n), addr) -> SET1 n, addr
/// Pattern: store(and(load(addr), ~(2^n)), addr) -> CLR1 n, addr
/// Pattern: store(xor(load(addr), 2^n), addr) -> NOT1 n, addr
static SDValue performSTORECombine(SDNode *N, SelectionDAG &DAG,
                                   const V850Subtarget &Subtarget) {
  StoreSDNode *ST = cast<StoreSDNode>(N);

  // Only match byte stores (SET1/CLR1/NOT1 operate on bytes)
  EVT VT = ST->getMemoryVT();
  if (VT != MVT::i8)
    return SDValue();

  // Don't match volatile stores (bit ops are read-modify-write)
  if (ST->isVolatile())
    return SDValue();

  // Get the value being stored
  SDValue StoreVal = ST->getValue();
  unsigned Opcode = StoreVal.getOpcode();

  // Must be OR, AND, or XOR
  if (Opcode != ISD::OR && Opcode != ISD::AND && Opcode != ISD::XOR)
    return SDValue();

  // One operand must be a load, the other a constant
  SDValue LoadOp, ConstOp;
  if (StoreVal.getOperand(0).getOpcode() == ISD::LOAD) {
    LoadOp = StoreVal.getOperand(0);
    ConstOp = StoreVal.getOperand(1);
  } else if (StoreVal.getOperand(1).getOpcode() == ISD::LOAD) {
    LoadOp = StoreVal.getOperand(1);
    ConstOp = StoreVal.getOperand(0);
  } else {
    return SDValue();
  }

  // The constant must be a ConstantSDNode
  auto *ConstNode = dyn_cast<ConstantSDNode>(ConstOp);
  if (!ConstNode)
    return SDValue();

  LoadSDNode *LD = cast<LoadSDNode>(LoadOp);

  // Don't match volatile loads
  if (LD->isVolatile())
    return SDValue();

  // Load and store must have the same address
  SDValue LoadAddr = LD->getBasePtr();
  SDValue StoreAddr = ST->getBasePtr();
  if (LoadAddr != StoreAddr)
    return SDValue();

  // Load must be zero-extending or sign-extending from i8
  // (or anyext, which is what we get for byte loads)
  if (LD->getMemoryVT() != MVT::i8)
    return SDValue();

  // The load must have only one use (the OR/AND/XOR operation)
  // Actually, it may have two uses: one for the value and one chain
  // Let's check if the load chain is used only by the store
  if (!LoadOp.hasOneUse())
    return SDValue();

  int64_t Const = ConstNode->getSExtValue();
  int BitNum = -1;
  unsigned V850Opcode;

  switch (Opcode) {
  case ISD::OR:
    // OR with power-of-2 sets a bit: x |= (1 << n)
    if (Const > 0 && Const < 256 && isPowerOf2_64(Const)) {
      BitNum = Log2_64(Const);
      V850Opcode = V850ISD::SET1_MEM;
    }
    break;
  case ISD::AND:
    // AND with ~(power-of-2) clears a bit: x &= ~(1 << n)
    // Const will be like 0xFB for clearing bit 2 (i.e., ~4)
    // But we're working with i8 after extension, so check byte range
    {
      uint8_t ByteConst = Const & 0xFF;
      uint8_t Inverted = ~ByteConst;
      if (Inverted != 0 && isPowerOf2_64(Inverted)) {
        BitNum = Log2_64(Inverted);
        V850Opcode = V850ISD::CLR1_MEM;
      }
    }
    break;
  case ISD::XOR:
    // XOR with power-of-2 toggles a bit: x ^= (1 << n)
    if (Const > 0 && Const < 256 && isPowerOf2_64(Const)) {
      BitNum = Log2_64(Const);
      V850Opcode = V850ISD::NOT1_MEM;
    }
    break;
  }

  if (BitNum < 0 || BitNum > 7)
    return SDValue();

  // Create the bit manipulation node
  SDLoc DL(N);
  SDValue Chain = ST->getChain();

  // We need to use the load's chain to ensure proper ordering
  // But we're replacing both the load and store with a single RMW operation
  Chain = LD->getChain();

  SDValue BitNumVal = DAG.getConstant(BitNum, DL, MVT::i32);

  // The SET1_MEM/CLR1_MEM/NOT1_MEM node: (chain, addr, bitnum) -> chain
  SDValue Ops[] = {Chain, StoreAddr, BitNumVal};
  return DAG.getNode(V850Opcode, DL, MVT::Other, Ops);
}

/// Try to combine multiply-add patterns into MAC/MACU instructions.
/// Pattern with ADDC/ADDE (when Legal):
///   mul_lo, mul_hi = SMUL/UMUL(a, b)
///   sum_lo, carry = ADDC(acc_lo, mul_lo)
///   sum_hi = ADDE(acc_hi, mul_hi, carry_in)
///
/// We look for the ADDE node and trace back to find the multiply-accumulate.
static SDValue performADDECombine(SDNode *N, SelectionDAG &DAG,
                                  const V850Subtarget &Subtarget) {
  // Only V850E2M and later have MAC/MACU
  if (!Subtarget.hasV850E2M())
    return SDValue();

  SDLoc DL(N);

  // ADDE has (LHS, RHS, CarryIn) - find which is mul_hi
  SDValue LHS = N->getOperand(0);
  SDValue RHS = N->getOperand(1);

  SDValue MulHi, AccHi;
  bool IsSigned = false;

  // Check if one operand is SMUL/UMUL result 1 (high part of multiply)
  auto checkMulHi = [&](SDValue V) -> bool {
    if (V.getResNo() != 1)
      return false;
    if (V.getOpcode() == V850ISD::SMUL) {
      IsSigned = true;
      return true;
    }
    if (V.getOpcode() == V850ISD::UMUL) {
      IsSigned = false;
      return true;
    }
    return false;
  };

  if (checkMulHi(LHS)) {
    MulHi = LHS;
    AccHi = RHS;
  } else if (checkMulHi(RHS)) {
    MulHi = RHS;
    AccHi = LHS;
  } else {
    return SDValue();
  }

  SDNode *MulNode = MulHi.getNode();

  // Now find the ADDC that produces the carry input to this ADDE
  // ADDC should have glue output that feeds into ADDE
  // We need to find the glue producer for this ADDE
  SDNode *GluedNode = N->getGluedNode();
  if (!GluedNode || GluedNode->getOpcode() != ISD::ADDC)
    return SDValue();

  // ADDC has (LHS, RHS) - find which is mul_lo
  SDValue ADDCOp0 = GluedNode->getOperand(0);
  SDValue ADDCOp1 = GluedNode->getOperand(1);

  auto isMulLow = [&](SDValue V) -> bool {
    if (V.getResNo() != 0)
      return false;
    if (V.getOpcode() != V850ISD::SMUL && V.getOpcode() != V850ISD::UMUL)
      return false;
    // Verify same multiply operands as MulHi
    return V.getOperand(0) == MulNode->getOperand(0) &&
           V.getOperand(1) == MulNode->getOperand(1);
  };

  SDValue AccLo;
  if (isMulLow(ADDCOp0)) {
    AccLo = ADDCOp1;
  } else if (isMulLow(ADDCOp1)) {
    AccLo = ADDCOp0;
  } else {
    return SDValue();
  }

  // We have a match! Create the MAC node.
  SDValue MulA = MulNode->getOperand(0);
  SDValue MulB = MulNode->getOperand(1);

  unsigned MacOpc = IsSigned ? V850ISD::SMAC : V850ISD::UMAC;
  SDValue MacOps[] = {MulA, MulB, AccLo, AccHi};
  SDVTList VTs = DAG.getVTList(MVT::i32, MVT::i32);
  SDValue Mac = DAG.getNode(MacOpc, DL, VTs, MacOps);

  // Replace ADDC uses (sum_lo) with MAC low result
  // Replace ADDE uses (sum_hi) with MAC high result
  // Following ARM's pattern for SMLAL/UMLAL combining
  DAG.ReplaceAllUsesOfValueWith(SDValue(GluedNode, 0),
                                SDValue(Mac.getNode(), 0));
  DAG.ReplaceAllUsesOfValueWith(SDValue(N, 0), SDValue(Mac.getNode(), 1));

  // Return original node to notify the driver to stop replacing
  return SDValue(N, 0);
}

/// Try to combine multiply-add patterns into MAC/MACU instructions.
/// Pattern after type legalization (legacy with setcc):
///   sum_lo = add acc_lo, mul_lo   (where mul_lo = SMUL/UMUL result 0)
///   carry = setcc sum_lo, acc_lo, setult
///   partial_hi = add acc_hi, mul_hi (where mul_hi = SMUL/UMUL result 1)
///   sum_hi = add partial_hi, carry
///
/// We look for the final add (sum_hi = add partial_hi, carry) and trace back.
static SDValue performADDCombine(SDNode *N, SelectionDAG &DAG,
                                 const V850Subtarget &Subtarget) {
  // Only V850E2M and later have MAC/MACU
  if (!Subtarget.hasV850E2M())
    return SDValue();

  SDLoc DL(N);

  // Look for: add (add acc_hi, mul_hi), carry
  // where carry = setcc (add acc_lo, mul_lo), acc_lo, setult
  SDValue LHS = N->getOperand(0);
  SDValue RHS = N->getOperand(1);

  // Find which operand is the carry (from setcc)
  SDValue PartialHi, Carry;
  if (LHS.getOpcode() == ISD::SETCC) {
    Carry = LHS;
    PartialHi = RHS;
  } else if (RHS.getOpcode() == ISD::SETCC) {
    Carry = RHS;
    PartialHi = LHS;
  } else {
    return SDValue();
  }

  // Verify the setcc is for unsigned less-than (carry detection)
  if (cast<CondCodeSDNode>(Carry.getOperand(2))->get() != ISD::SETULT)
    return SDValue();

  // PartialHi should be: add acc_hi, mul_hi
  if (PartialHi.getOpcode() != ISD::ADD)
    return SDValue();

  // Find mul_hi from PartialHi = add acc_hi, mul_hi
  SDValue MulHi, AccHi;
  bool IsSigned = false;

  SDValue PHOp0 = PartialHi.getOperand(0);
  SDValue PHOp1 = PartialHi.getOperand(1);

  if (PHOp0.getOpcode() == V850ISD::SMUL && PHOp0.getResNo() == 1) {
    MulHi = PHOp0;
    AccHi = PHOp1;
    IsSigned = true;
  } else if (PHOp0.getOpcode() == V850ISD::UMUL && PHOp0.getResNo() == 1) {
    MulHi = PHOp0;
    AccHi = PHOp1;
    IsSigned = false;
  } else if (PHOp1.getOpcode() == V850ISD::SMUL && PHOp1.getResNo() == 1) {
    MulHi = PHOp1;
    AccHi = PHOp0;
    IsSigned = true;
  } else if (PHOp1.getOpcode() == V850ISD::UMUL && PHOp1.getResNo() == 1) {
    MulHi = PHOp1;
    AccHi = PHOp0;
    IsSigned = false;
  } else {
    return SDValue();
  }

  SDNode *MulHiNode = MulHi.getNode();

  // Carry = setcc sum_lo, acc_lo, setult
  // sum_lo should be: add acc_lo, mul_lo
  SDValue SumLo = Carry.getOperand(0);
  SDValue CompareOp = Carry.getOperand(1); // Should be acc_lo

  if (SumLo.getOpcode() != ISD::ADD)
    return SDValue();

  // Find mul_lo from SumLo = add acc_lo, mul_lo
  // Note: For unsigned, the low multiply may use SMUL while high uses UMUL
  // (the low 32 bits are identical for signed/unsigned multiply)
  SDValue AccLo;
  SDValue SLOp0 = SumLo.getOperand(0);
  SDValue SLOp1 = SumLo.getOperand(1);

  auto isMulLow = [&](SDValue V) -> bool {
    // Check if this is a mul result 0 with the same operands as MulHi
    if (V.getResNo() != 0)
      return false;
    if (V.getOpcode() != V850ISD::SMUL && V.getOpcode() != V850ISD::UMUL)
      return false;
    // Verify same multiply operands
    return V.getOperand(0) == MulHiNode->getOperand(0) &&
           V.getOperand(1) == MulHiNode->getOperand(1);
  };

  if (isMulLow(SLOp0)) {
    AccLo = SLOp1;
  } else if (isMulLow(SLOp1)) {
    AccLo = SLOp0;
  } else {
    return SDValue();
  }

  // Verify CompareOp is AccLo (the setcc should compare sum_lo with acc_lo)
  if (CompareOp != AccLo)
    return SDValue();

  // We have a match! Create the MAC node.
  // Use the multiply operands (same for both MulHi and MulLo nodes)
  SDValue MulA = MulHiNode->getOperand(0);
  SDValue MulB = MulHiNode->getOperand(1);

  unsigned MacOpc = IsSigned ? V850ISD::SMAC : V850ISD::UMAC;
  SDValue MacOps[] = {MulA, MulB, AccLo, AccHi};
  SDVTList VTs = DAG.getVTList(MVT::i32, MVT::i32);
  SDValue Mac = DAG.getNode(MacOpc, DL, VTs, MacOps);

  // Replace SumLo uses with MAC low result
  DAG.ReplaceAllUsesOfValueWith(SumLo, Mac.getValue(0));

  // Return high part for this ADD node
  return Mac.getValue(1);
}

/// Convert V850 condition code enum to ISD condition code
static ISD::CondCode getV850CondCode(unsigned CC) {
  switch (CC) {
  case 0:
    return ISD::SETFALSE; // V (always false/overflow)
  case 1:
    return ISD::SETUO; // C/L (carry/unsigned less)
  case 2:
    return ISD::SETEQ; // Z (zero/equal)
  case 3:
    return ISD::SETULE; // NH (not higher/unsigned <=)
  case 4:
    return ISD::SETLT; // S/N (negative/signed <)
  case 5:
    return ISD::SETTRUE; // T (always true)
  case 6:
    return ISD::SETLT; // LT (signed less than)
  case 7:
    return ISD::SETLE; // LE (signed less or equal)
  case 8:
    return ISD::SETTRUE; // NV (not overflow - always true approx)
  case 9:
    return ISD::SETUGE; // NC/NL (no carry/unsigned >=)
  case 10:
    return ISD::SETNE; // NZ (not zero/not equal)
  case 11:
    return ISD::SETUGT; // H (higher/unsigned >)
  case 12:
    return ISD::SETGE; // NS/P (not negative/positive)
  case 13:
    return ISD::SETFALSE; // SA (saturated - special)
  case 14:
    return ISD::SETGE; // GE (signed greater or equal)
  case 15:
    return ISD::SETGT; // GT (signed greater than)
  default:
    return ISD::SETCC_INVALID;
  }
}

/// Convert ISD condition code to V850 condition code enum
static unsigned getV850CondCodeValue(ISD::CondCode CC) {
  switch (CC) {
  case ISD::SETEQ:
    return 2; // Z
  case ISD::SETNE:
    return 10; // NZ
  case ISD::SETLT:
    return 6; // LT (signed)
  case ISD::SETLE:
    return 7; // LE (signed)
  case ISD::SETGT:
    return 15; // GT (signed)
  case ISD::SETGE:
    return 14; // GE (signed)
  case ISD::SETULT:
    return 1; // C/L (unsigned <)
  case ISD::SETULE:
    return 3; // NH (unsigned <=)
  case ISD::SETUGT:
    return 11; // H (unsigned >)
  case ISD::SETUGE:
    return 9; // NC/NL (unsigned >=)
  default:
    return ~0U; // Invalid
  }
}

/// Match SASF pattern: (or (shl x, 1), (setcc LHS, RHS, cond))
/// SASF shifts left by 1 and sets bit 0 based on condition code.
/// This is available on V850ES and later.
static SDValue performORCombine(SDNode *N, SelectionDAG &DAG,
                                const V850Subtarget &Subtarget) {
  // SASF is available on V850ES (V850E1) and later
  if (!Subtarget.hasV850E1())
    return SDValue();

  SDLoc DL(N);
  SDValue LHS = N->getOperand(0);
  SDValue RHS = N->getOperand(1);

  // Match pattern: (or (shl x, 1), condition_value)
  // where condition_value is 0 or 1 based on a comparison

  // Find which operand is the shift
  SDValue ShiftOp, CondOp;
  if (LHS.getOpcode() == ISD::SHL) {
    ShiftOp = LHS;
    CondOp = RHS;
  } else if (RHS.getOpcode() == ISD::SHL) {
    ShiftOp = RHS;
    CondOp = LHS;
  } else {
    return SDValue();
  }

  // Verify shift amount is 1
  auto *ShiftAmt = dyn_cast<ConstantSDNode>(ShiftOp.getOperand(1));
  if (!ShiftAmt || ShiftAmt->getZExtValue() != 1)
    return SDValue();

  SDValue ShiftInput = ShiftOp.getOperand(0);

  // Match condition value - either direct setcc or (and (setcc ...), 1)
  SDValue SetCC;
  if (CondOp.getOpcode() == ISD::SETCC) {
    SetCC = CondOp;
  } else if (CondOp.getOpcode() == ISD::AND) {
    // Check for (and (setcc ...), 1)
    auto *Mask = dyn_cast<ConstantSDNode>(CondOp.getOperand(1));
    if (!Mask || Mask->getZExtValue() != 1)
      return SDValue();
    if (CondOp.getOperand(0).getOpcode() != ISD::SETCC)
      return SDValue();
    SetCC = CondOp.getOperand(0);
  } else if (CondOp.getOpcode() == ISD::ZERO_EXTEND) {
    // Check for (zext (setcc ...))
    if (CondOp.getOperand(0).getOpcode() != ISD::SETCC)
      return SDValue();
    SetCC = CondOp.getOperand(0);
  } else {
    return SDValue();
  }

  // Extract comparison operands and condition code
  SDValue CmpLHS = SetCC.getOperand(0);
  SDValue CmpRHS = SetCC.getOperand(1);
  ISD::CondCode CC = cast<CondCodeSDNode>(SetCC.getOperand(2))->get();

  // Convert ISD condition code to V850 condition code
  unsigned V850CC = getV850CondCodeValue(CC);
  if (V850CC == ~0U)
    return SDValue(); // Unsupported condition

  // Emit CMP instruction which produces Glue with PSW flags
  SDValue Cmp = DAG.getNode(V850ISD::CMP, DL, MVT::Glue, CmpLHS, CmpRHS);

  // Create V850ISD::SASF node: (input, condcode, glue)
  // The SASF consumes the glue from CMP to use PSW flags
  SDValue CCVal = DAG.getConstant(V850CC, DL, MVT::i32);
  return DAG.getNode(V850ISD::SASF, DL, MVT::i32, ShiftInput, CCVal, Cmp);
}

SDValue V850TargetLowering::PerformDAGCombine(SDNode *N,
                                              DAGCombinerInfo &DCI) const {
  SelectionDAG &DAG = DCI.DAG;

  switch (N->getOpcode()) {
  default:
    break;
  case ISD::ADD:
    return performADDCombine(N, DAG, Subtarget);
  case ISD::ADDE:
    return performADDECombine(N, DAG, Subtarget);
  case ISD::STORE:
    return performSTORECombine(N, DAG, Subtarget);
  case ISD::OR:
    return performORCombine(N, DAG, Subtarget);
  }

  return SDValue();
}

//===----------------------------------------------------------------------===//
// Inline Assembly Support
//===----------------------------------------------------------------------===//

/// getConstraintType - Given a constraint letter, return the type of
/// constraint it is for this target.
V850TargetLowering::ConstraintType
V850TargetLowering::getConstraintType(StringRef Constraint) const {
  if (Constraint.size() == 1) {
    switch (Constraint[0]) {
    default:
      break;
    case 'r':
      return C_RegisterClass;
    }
  }
  return TargetLowering::getConstraintType(Constraint);
}

std::pair<unsigned, const TargetRegisterClass *>
V850TargetLowering::getRegForInlineAsmConstraint(const TargetRegisterInfo *TRI,
                                                 StringRef Constraint,
                                                 MVT VT) const {
  if (Constraint.size() == 1) {
    switch (Constraint[0]) {
    case 'r':
      if (VT == MVT::i32 || VT == MVT::i16 || VT == MVT::i8)
        return std::make_pair(0U, &V850::GPRRegClass);
      break;
    }
  }

  return TargetLowering::getRegForInlineAsmConstraint(TRI, Constraint, VT);
}

//===----------------------------------------------------------------------===//
// Tail Call Optimization
//===----------------------------------------------------------------------===//

bool V850TargetLowering::isEligibleForTailCallOptimization(
    CCState &CCInfo, CallLoweringInfo &CLI, MachineFunction &MF,
    const SmallVectorImpl<CCValAssign> &ArgLocs) const {

  auto CalleeCC = CLI.CallConv;
  auto &Outs = CLI.Outs;
  auto &Caller = MF.getFunction();
  auto CallerCC = Caller.getCallingConv();

  // Do not tail call opt if the stack is used to pass parameters.
  if (CCInfo.getStackSize() != 0)
    return false;

  // Do not tail call opt if any parameters need to be passed indirectly.
  for (auto &VA : ArgLocs)
    if (VA.getLocInfo() == CCValAssign::Indirect)
      return false;

  // Do not tail call opt if either caller or callee uses struct return
  // semantics.
  auto IsCallerStructRet = Caller.hasStructRetAttr();
  auto IsCalleeStructRet = Outs.empty() ? false : Outs[0].Flags.isSRet();
  if (IsCallerStructRet || IsCalleeStructRet)
    return false;

  // Do not tail call opt if either the callee or caller has a byval argument.
  for (auto &Arg : Outs)
    if (Arg.Flags.isByVal())
      return false;

  // The callee has to preserve all registers the caller needs to preserve.
  const V850RegisterInfo *TRI = Subtarget.getRegisterInfo();
  const uint32_t *CallerPreserved = TRI->getCallPreservedMask(MF, CallerCC);
  if (CalleeCC != CallerCC) {
    const uint32_t *CalleePreserved = TRI->getCallPreservedMask(MF, CalleeCC);
    if (!TRI->regmaskSubsetEqual(CallerPreserved, CalleePreserved))
      return false;
  }

  return true;
}

//===----------------------------------------------------------------------===//
// Atomic Operations
//===----------------------------------------------------------------------===//

TargetLowering::AtomicExpansionKind
V850TargetLowering::shouldExpandAtomicCmpXchgInIR(AtomicCmpXchgInst *CI) const {
  // V850E2M has CAXI for 32-bit compare-and-swap
  // Don't expand it - let it be lowered to the CAXI instruction
  unsigned Size = CI->getCompareOperand()->getType()->getPrimitiveSizeInBits();
  if (Subtarget.hasV850E2M() && Size == 32)
    return AtomicExpansionKind::None;

  // For other sizes or without V850E2M, use library calls
  return AtomicExpansionKind::None;
}

TargetLowering::AtomicExpansionKind
V850TargetLowering::shouldExpandAtomicRMWInIR(AtomicRMWInst *AI) const {
  unsigned Size = AI->getType()->getPrimitiveSizeInBits();
  if (Size != 32)
    return AtomicExpansionKind::None;

  // RH850G3M has LDL.W/STC.W (load-linked/store-conditional) which is more
  // efficient for atomic RMW than CAXI-based CAS loops. LDL.W/STC.W avoids
  // the double-load overhead of compare-and-swap.
  if (Subtarget.hasRH850G3M())
    return AtomicExpansionKind::LLSC;

  // V850E2M has CAXI for 32-bit compare-and-swap
  if (Subtarget.hasV850E2M())
    return AtomicExpansionKind::CmpXChg;

  return AtomicExpansionKind::None;
}

Value *V850TargetLowering::emitLoadLinked(IRBuilderBase &Builder, Type *ValueTy,
                                          Value *Addr,
                                          AtomicOrdering Ord) const {
  // Use LDL.W (load-linked) intrinsic for G3M.
  // V850's LDL.W has no ordering variants, so emit explicit SYNCP fence
  // for release/acq_rel/seq_cst orderings (leading fence).
  Module *M = Builder.GetInsertBlock()->getModule();

  if (isReleaseOrStronger(Ord)) {
    Function *Syncp =
        Intrinsic::getOrInsertDeclaration(M, Intrinsic::v850_syncp);
    Builder.CreateCall(Syncp);
  }

  Function *LDL = Intrinsic::getOrInsertDeclaration(M, Intrinsic::v850_ldl_w);
  return Builder.CreateCall(LDL, {Addr}, "ldl");
}

Value *V850TargetLowering::emitStoreConditional(IRBuilderBase &Builder,
                                                Value *Val, Value *Addr,
                                                AtomicOrdering Ord) const {
  // Use STC.W (store-conditional) intrinsic for G3M.
  // STC.W returns 1 on success, 0 on failure.
  // LLVM AtomicExpandPass expects 0 on success, non-zero on failure.
  // Invert the result with XOR.
  Module *M = Builder.GetInsertBlock()->getModule();
  Function *STC = Intrinsic::getOrInsertDeclaration(M, Intrinsic::v850_stc_w);
  Value *Result = Builder.CreateCall(STC, {Addr, Val}, "stc");

  // V850's STC.W has no ordering variants, so emit explicit SYNCP fence
  // for acquire/acq_rel/seq_cst orderings (trailing fence).
  if (isAcquireOrStronger(Ord)) {
    Function *Syncp =
        Intrinsic::getOrInsertDeclaration(M, Intrinsic::v850_syncp);
    Builder.CreateCall(Syncp);
  }

  return Builder.CreateXor(Result, ConstantInt::get(Result->getType(), 1),
                           "stc.fail");
}

void V850TargetLowering::emitAtomicCmpXchgNoStoreLLBalance(
    IRBuilderBase &Builder) const {
  // Emit CLL (clear load link) to release the exclusive monitor when
  // a cmpxchg comparison fails and the store-conditional is skipped.
  // This prevents holding the exclusive monitor unnecessarily.
  Module *M = Builder.GetInsertBlock()->getModule();
  Function *CLL = Intrinsic::getOrInsertDeclaration(M, Intrinsic::v850_cll);
  Builder.CreateCall(CLL);
}

//===----------------------------------------------------------------------===//
// Custom Instruction Insertion
//===----------------------------------------------------------------------===//

/// EmitReadFPUReg - Emit the instruction sequence to read an FPU system
/// register with proper BSEL banking.
///
/// Expansion:
///   movhi 0x20, r0, $scratch  ; $scratch = 0x2000 (FPU bank)
///   ldsr  $scratch, bsel      ; Select FPU bank
///   stsr  fpu_reg, $result    ; Read FPU register
///   mov   r0, $scratch        ; $scratch = 0
///   ldsr  $scratch, bsel      ; Restore CPU main bank
static void EmitReadFPUReg(MachineInstr &MI, MachineBasicBlock *MBB,
                           const TargetInstrInfo &TII, unsigned FPURegNo,
                           Register ResultReg, Register ScratchReg1,
                           Register ScratchReg2) {
  DebugLoc DL = MI.getDebugLoc();

  // FPU system register regIDs: FPSR=6, FPEPC=7, FPST=8, FPCC=9, FPCFG=10,
  // FPEC=11
  static const unsigned FPURegIDs[] = {6, 7, 8, 9, 10, 11};
  // BSEL regID = 31
  static const unsigned BSELRegID = 31;

  // movhi 0x20, r0, $scratch1  ; $scratch1 = 0x2000 (FPU Status Bank)
  BuildMI(*MBB, MI, DL, TII.get(V850::MOVHI), ScratchReg1)
      .addImm(0x20)
      .addReg(V850::R0);

  // ldsr $scratch1, bsel  ; Select FPU bank
  BuildMI(*MBB, MI, DL, TII.get(V850::LDSR))
      .addReg(ScratchReg1)
      .addImm(BSELRegID);

  // stsr fpu_reg, $result  ; Read FPU register
  BuildMI(*MBB, MI, DL, TII.get(V850::STSR), ResultReg)
      .addImm(FPURegIDs[FPURegNo]);

  // mov r0, $scratch2  ; $scratch2 = 0
  BuildMI(*MBB, MI, DL, TII.get(V850::MOV), ScratchReg2).addReg(V850::R0);

  // ldsr $scratch2, bsel  ; Restore CPU main bank
  BuildMI(*MBB, MI, DL, TII.get(V850::LDSR))
      .addReg(ScratchReg2)
      .addImm(BSELRegID);
}

/// EmitWriteFPUReg - Emit the instruction sequence to write an FPU system
/// register with proper BSEL banking.
///
/// Expansion:
///   movhi 0x20, r0, $scratch  ; $scratch = 0x2000 (FPU bank)
///   ldsr  $scratch, bsel      ; Select FPU bank
///   ldsr  $value, fpu_reg     ; Write FPU register
///   mov   r0, $scratch        ; $scratch = 0
///   ldsr  $scratch, bsel      ; Restore CPU main bank
static void EmitWriteFPUReg(MachineInstr &MI, MachineBasicBlock *MBB,
                            const TargetInstrInfo &TII, unsigned FPURegNo,
                            Register ValueReg, Register ScratchReg1,
                            Register ScratchReg2) {
  DebugLoc DL = MI.getDebugLoc();

  // FPU system register regIDs: FPSR=6, FPEPC=7, FPST=8, FPCC=9, FPCFG=10,
  // FPEC=11
  static const unsigned FPURegIDs[] = {6, 7, 8, 9, 10, 11};
  // BSEL regID = 31
  static const unsigned BSELRegID = 31;

  // movhi 0x20, r0, $scratch1  ; $scratch1 = 0x2000 (FPU Status Bank)
  BuildMI(*MBB, MI, DL, TII.get(V850::MOVHI), ScratchReg1)
      .addImm(0x20)
      .addReg(V850::R0);

  // ldsr $scratch1, bsel  ; Select FPU bank
  BuildMI(*MBB, MI, DL, TII.get(V850::LDSR))
      .addReg(ScratchReg1)
      .addImm(BSELRegID);

  // ldsr $value, fpu_reg  ; Write FPU register
  BuildMI(*MBB, MI, DL, TII.get(V850::LDSR))
      .addReg(ValueReg)
      .addImm(FPURegIDs[FPURegNo]);

  // mov r0, $scratch2  ; $scratch2 = 0
  BuildMI(*MBB, MI, DL, TII.get(V850::MOV), ScratchReg2).addReg(V850::R0);

  // ldsr $scratch2, bsel  ; Restore CPU main bank
  BuildMI(*MBB, MI, DL, TII.get(V850::LDSR))
      .addReg(ScratchReg2)
      .addImm(BSELRegID);
}

MachineBasicBlock *
V850TargetLowering::EmitInstrWithCustomInserter(MachineInstr &MI,
                                                MachineBasicBlock *MBB) const {
  const TargetInstrInfo &TII = *Subtarget.getInstrInfo();
  MachineFunction &MF = *MBB->getParent();
  MachineRegisterInfo &MRI = MF.getRegInfo();

  switch (MI.getOpcode()) {
  default:
    llvm_unreachable("Unexpected instr type to insert");

  case V850::TST1_PSEUDO: {
    // Expand: TST1_PSEUDO $result, $bit, [$addr]
    // To:     TST1r $bit, [$addr]    ; Sets Z flag if bit was 0
    //         SETF z, $result        ; $result = Z flag (1 if bit was 0)
    DebugLoc DL = MI.getDebugLoc();

    Register ResultReg = MI.getOperand(0).getReg();
    Register BitReg = MI.getOperand(1).getReg();
    Register AddrReg = MI.getOperand(2).getReg();

    // TST1r sets Z flag: Z=1 if the tested bit was 0
    BuildMI(*MBB, MI, DL, TII.get(V850::TST1r)).addReg(BitReg).addReg(AddrReg);

    // SETF z, result: result = 1 if Z=1 (bit was 0), else result = 0
    // Condition code 2 = "z" (zero/equal)
    BuildMI(*MBB, MI, DL, TII.get(V850::SETF), ResultReg).addImm(2); // CC_Z = 2

    MI.eraseFromParent();
    return MBB;
  }

  // FPU System Register Read Pseudo-Instructions
  // These expand to the BSEL banking sequence for V850E2M
  case V850::READ_FPSR:
  case V850::READ_FPEPC:
  case V850::READ_FPST:
  case V850::READ_FPCC:
  case V850::READ_FPCFG:
  case V850::READ_FPEC: {
    Register ResultReg = MI.getOperand(0).getReg();
    // Allocate two scratch registers for BSEL manipulation (SSA form)
    Register ScratchReg1 = MRI.createVirtualRegister(&V850::GPRRegClass);
    Register ScratchReg2 = MRI.createVirtualRegister(&V850::GPRRegClass);

    // Map opcode to FPU register index (0=FPSR, 1=FPEPC, etc.)
    unsigned FPURegNo;
    switch (MI.getOpcode()) {
    case V850::READ_FPSR:
      FPURegNo = 0;
      break;
    case V850::READ_FPEPC:
      FPURegNo = 1;
      break;
    case V850::READ_FPST:
      FPURegNo = 2;
      break;
    case V850::READ_FPCC:
      FPURegNo = 3;
      break;
    case V850::READ_FPCFG:
      FPURegNo = 4;
      break;
    case V850::READ_FPEC:
      FPURegNo = 5;
      break;
    default:
      llvm_unreachable("Invalid READ_FPU pseudo");
    }

    EmitReadFPUReg(MI, MBB, TII, FPURegNo, ResultReg, ScratchReg1, ScratchReg2);
    MI.eraseFromParent();
    return MBB;
  }

  // FPU System Register Write Pseudo-Instructions
  case V850::WRITE_FPSR:
  case V850::WRITE_FPEPC:
  case V850::WRITE_FPST:
  case V850::WRITE_FPCC:
  case V850::WRITE_FPCFG:
  case V850::WRITE_FPEC: {
    Register ValueReg = MI.getOperand(0).getReg();
    // Allocate two scratch registers for BSEL manipulation (SSA form)
    Register ScratchReg1 = MRI.createVirtualRegister(&V850::GPRRegClass);
    Register ScratchReg2 = MRI.createVirtualRegister(&V850::GPRRegClass);

    // Map opcode to FPU register index
    unsigned FPURegNo;
    switch (MI.getOpcode()) {
    case V850::WRITE_FPSR:
      FPURegNo = 0;
      break;
    case V850::WRITE_FPEPC:
      FPURegNo = 1;
      break;
    case V850::WRITE_FPST:
      FPURegNo = 2;
      break;
    case V850::WRITE_FPCC:
      FPURegNo = 3;
      break;
    case V850::WRITE_FPCFG:
      FPURegNo = 4;
      break;
    case V850::WRITE_FPEC:
      FPURegNo = 5;
      break;
    default:
      llvm_unreachable("Invalid WRITE_FPU pseudo");
    }

    EmitWriteFPUReg(MI, MBB, TII, FPURegNo, ValueReg, ScratchReg1, ScratchReg2);
    MI.eraseFromParent();
    return MBB;
  }

  case V850::CMOV_F64: {
    // Expand CMOV_F64 cond, %true, %false → %dst
    // into two CMOVr instructions operating on the lo and hi GPR halves of
    // the DPR register pair, then combine with REG_SEQUENCE.
    DebugLoc DL = MI.getDebugLoc();
    Register DstReg = MI.getOperand(0).getReg();
    int64_t Cond = MI.getOperand(1).getImm();
    Register TrueReg = MI.getOperand(2).getReg();
    Register FalseReg = MI.getOperand(3).getReg();

    Register TrueLo = MRI.createVirtualRegister(&V850::GPRRegClass);
    Register TrueHi = MRI.createVirtualRegister(&V850::GPRRegClass);
    Register FalseLo = MRI.createVirtualRegister(&V850::GPRRegClass);
    Register FalseHi = MRI.createVirtualRegister(&V850::GPRRegClass);
    Register ResLo = MRI.createVirtualRegister(&V850::GPRRegClass);
    Register ResHi = MRI.createVirtualRegister(&V850::GPRRegClass);

    auto Iter = MI.getIterator();

    // Extract the lo and hi 32-bit GPR halves from each DPR operand.
    BuildMI(*MBB, Iter, DL, TII.get(TargetOpcode::COPY), TrueLo)
        .addReg(TrueReg, 0, llvm::sub_lo);
    BuildMI(*MBB, Iter, DL, TII.get(TargetOpcode::COPY), TrueHi)
        .addReg(TrueReg, 0, llvm::sub_hi);
    BuildMI(*MBB, Iter, DL, TII.get(TargetOpcode::COPY), FalseLo)
        .addReg(FalseReg, 0, llvm::sub_lo);
    BuildMI(*MBB, Iter, DL, TII.get(TargetOpcode::COPY), FalseHi)
        .addReg(FalseReg, 0, llvm::sub_hi);

    // Conditionally select each half using CMOVr (reads PSW for condition).
    BuildMI(*MBB, Iter, DL, TII.get(V850::CMOVr), ResLo)
        .addImm(Cond)
        .addReg(TrueLo)
        .addReg(FalseLo);
    BuildMI(*MBB, Iter, DL, TII.get(V850::CMOVr), ResHi)
        .addImm(Cond)
        .addReg(TrueHi)
        .addReg(FalseHi);

    // Combine the two GPR halves into the DPR output register.
    BuildMI(*MBB, Iter, DL, TII.get(TargetOpcode::REG_SEQUENCE), DstReg)
        .addReg(ResLo)
        .addImm(llvm::sub_lo)
        .addReg(ResHi)
        .addImm(llvm::sub_hi);

    MI.eraseFromParent();
    return MBB;
  }
  }
}
