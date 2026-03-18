//===-- V850ISelLowering.h - V850 DAG Lowering Interface --------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines the interfaces that V850 uses to lower LLVM code into a
// selection DAG.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V850_V850ISELLOWERING_H
#define LLVM_LIB_TARGET_V850_V850ISELLOWERING_H

#include "V850.h"
#include "llvm/CodeGen/SelectionDAG.h"
#include "llvm/CodeGen/TargetLowering.h"
#include "llvm/IR/Instructions.h"

namespace llvm {

class V850Subtarget;

namespace V850ISD {
enum NodeType : unsigned {
  FIRST_NUMBER = ISD::BUILTIN_OP_END,
  RET_GLUE,  // Return with a glue operand
  CALL,      // Function call
  TAIL,      // Tail call
  WRAPPER,   // Global address wrapper
  GPRel,     // GP-relative address (small data section)
  BR_CC,     // Branch on condition code
  CMP,       // Compare
  SELECT_CC, // Select with condition code

  // Multiply operations (V850E1+)
  // SMUL: Signed 32x32->64 multiply, returns (low, high)
  SMUL,
  // UMUL: Unsigned 32x32->64 multiply, returns (low, high)
  UMUL,
  // MULH16: Signed 16x16->32 multiply (MULH instruction)
  // More efficient than SMUL when both operands are sign-extended i16
  MULH16,

  // Division operations (V850E1+)
  // SDIVREM: Signed divide, returns (quotient, remainder)
  SDIVREM,
  // UDIVREM: Unsigned divide, returns (quotient, remainder)
  UDIVREM,

  // Multiply-accumulate operations (V850E2M+)
  // SMAC: Signed multiply-accumulate
  // (res_lo, res_hi) = (acc_lo, acc_hi) + sext(a) * sext(b)
  SMAC,
  // UMAC: Unsigned multiply-accumulate
  // (res_lo, res_hi) = (acc_lo, acc_hi) + zext(a) * zext(b)
  UMAC,

  // Memory bit manipulation operations (atomic RMW)
  // SET1_MEM: Set bit in memory byte - chain = SET1_MEM chain, addr, bitnum
  SET1_MEM,
  // CLR1_MEM: Clear bit in memory byte - chain = CLR1_MEM chain, addr, bitnum
  CLR1_MEM,
  // NOT1_MEM: Toggle bit in memory byte - chain = NOT1_MEM chain, addr, bitnum
  NOT1_MEM,
  // TST1_MEM: Test bit in memory - (result, chain) = TST1_MEM chain, addr,
  // bitnum Returns 1 if bit was 0 (Z flag set), 0 otherwise
  TST1_MEM,

  // BR_JT: Jump table branch using SWITCH instruction (V850E1+)
  // chain = BR_JT chain, index, jumptable
  // The SWITCH instruction reads a halfword offset from a table and branches.
  BR_JT,

  // SASF: Shift and Set Flag (V850ES+)
  // result = (input << 1) | (condition ? 1 : 0)
  // SASF input, LHS, RHS, condcode
  // First CMP LHS, RHS sets PSW, then SASF checks condition and shifts.
  SASF,

  // FP_CMP: Floating-point compare (V850E2M+ FPU)
  // Emits CMPF.S/D + TRFSR to set PSW.Z from FP comparison result.
  // Operands: (fcond, lhs, rhs) → Glue (PSW flags)
  // After execution, PSW.Z = 1 if comparison is true, 0 if false.
  // Use BZ/SETF Z for "true" branch, BNZ/SETF NZ for "false" branch.
  FP_CMP,

  // FP_SELECT_CC: Floating-point conditional select using CMOVF.S/D
  // Emits CMPF.S/D + CMOVF.S/D (2 insn instead of CMPF+TRFSR+CMOV = 3 insn).
  // Operands: (fcond, cmp_lhs, cmp_rhs, true_val, false_val)
  // Returns: selected value (true_val if comparison true, false_val otherwise)
  FP_SELECT_CC,

  // i64 <-> FP conversion nodes (V850E2M+ FPU hardware instructions).
  // These use i32 pair operands since i64 is not a legal type on V850.

  // SINT64_TO_FP: (i32_lo, i32_hi) -> f32 or f64
  // Maps to CVTF.LS (-> f32) or CVTF.LD (-> f64)
  SINT64_TO_FP,

  // UINT64_TO_FP: (i32_lo, i32_hi) -> f32 or f64
  // Maps to CVTF.ULS (-> f32) or CVTF.ULD (-> f64)
  UINT64_TO_FP,

  // FP_TO_SINT64: (f32 or f64) -> (i32_lo, i32_hi)
  // Maps to TRNCF.SL (f32 ->) or TRNCF.DL (f64 ->)
  FP_TO_SINT64,

  // FP_TO_UINT64: (f32 or f64) -> (i32_lo, i32_hi)
  // Maps to TRNCF.SUL (f32 ->) or TRNCF.DUL (f64 ->)
  FP_TO_UINT64,
};
} // namespace V850ISD

class V850TargetLowering : public TargetLowering {
public:
  explicit V850TargetLowering(const TargetMachine &TM,
                              const V850Subtarget &STI);

  MVT getScalarShiftAmountTy(const DataLayout &, EVT) const override {
    return MVT::i32;
  }

  /// LowerOperation - Provide custom lowering hooks for some operations.
  SDValue LowerOperation(SDValue Op, SelectionDAG &DAG) const override;

  /// getTargetNodeName - Return the name of a target specific DAG node.
  const char *getTargetNodeName(unsigned Opcode) const override;

  SDValue LowerGlobalAddress(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerExternalSymbol(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerBlockAddress(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerConstantPool(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerBR_CC(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerSELECT_CC(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerRETURNADDR(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerFRAMEADDR(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerMUL(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerMULHS(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerMULHU(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerMUL_LOHI(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerDivRem(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerINTRINSIC_W_CHAIN(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerBR_JT(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerVASTART(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerATOMIC_FENCE(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerATOMIC_LOAD(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerATOMIC_STORE(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerSINT_TO_FP_I64(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerUINT_TO_FP_I64(SDValue Op, SelectionDAG &DAG) const;

  /// ReplaceNodeResults - Replace results of illegal nodes with custom code.
  void ReplaceNodeResults(SDNode *N, SmallVectorImpl<SDValue> &Results,
                          SelectionDAG &DAG) const override;

  /// getJumpTableEncoding - Return the entry encoding for jump tables.
  /// V850E1+ uses inline jump tables with SWITCH instruction.
  unsigned getJumpTableEncoding() const override;

  /// PerformDAGCombine - Perform target-specific DAG combining.
  SDValue PerformDAGCombine(SDNode *N, DAGCombinerInfo &DCI) const override;

  Register getRegisterByName(const char *RegName, LLT VT,
                             const MachineFunction &MF) const override;

  // Inline assembly support
  ConstraintType getConstraintType(StringRef Constraint) const override;
  std::pair<unsigned, const TargetRegisterClass *>
  getRegForInlineAsmConstraint(const TargetRegisterInfo *TRI,
                               StringRef Constraint, MVT VT) const override;

  // Atomic operation support
  TargetLowering::AtomicExpansionKind
  shouldExpandAtomicCmpXchgInIR(AtomicCmpXchgInst *CI) const override;

  TargetLowering::AtomicExpansionKind
  shouldExpandAtomicRMWInIR(AtomicRMWInst *AI) const override;

  bool shouldInsertFencesForAtomic(const Instruction *I) const override;

  // LL/SC support for RH850G3M (LDL.W/STC.W)
  Value *emitLoadLinked(IRBuilderBase &Builder, Type *ValueTy, Value *Addr,
                        AtomicOrdering Ord) const override;
  Value *emitStoreConditional(IRBuilderBase &Builder, Value *Val, Value *Addr,
                              AtomicOrdering Ord) const override;
  void emitAtomicCmpXchgNoStoreLLBalance(IRBuilderBase &Builder) const override;

  /// isFMAFasterThanFMulAndFAdd - Return true if an FMA operation is faster
  /// than a pair of fmul and fadd instructions. fmuladd intrinsics will be
  /// expanded to FMAs when this method returns true, otherwise fmuladd is
  /// expanded to fmul + fadd.
  bool isFMAFasterThanFMulAndFAdd(const MachineFunction &MF,
                                  EVT VT) const override;

  // Post-indexed addressing support (RH850G4MH+)
  bool getPostIndexedAddressParts(SDNode *N, SDNode *Op, SDValue &Base,
                                  SDValue &Offset, ISD::MemIndexedMode &AM,
                                  SelectionDAG &DAG) const override;

  // Custom instruction insertion for pseudo instructions
  MachineBasicBlock *
  EmitInstrWithCustomInserter(MachineInstr &MI,
                              MachineBasicBlock *MBB) const override;

private:
  const V850Subtarget &Subtarget;

  bool isEligibleForTailCallOptimization(
      CCState &CCInfo, CallLoweringInfo &CLI, MachineFunction &MF,
      const SmallVectorImpl<CCValAssign> &ArgLocs) const;

  SDValue LowerFormalArguments(SDValue Chain, CallingConv::ID CallConv,
                               bool isVarArg,
                               const SmallVectorImpl<ISD::InputArg> &Ins,
                               const SDLoc &dl, SelectionDAG &DAG,
                               SmallVectorImpl<SDValue> &InVals) const override;

  SDValue LowerCall(TargetLowering::CallLoweringInfo &CLI,
                    SmallVectorImpl<SDValue> &InVals) const override;

  bool CanLowerReturn(CallingConv::ID CallConv, MachineFunction &MF,
                      bool IsVarArg,
                      const SmallVectorImpl<ISD::OutputArg> &Outs,
                      LLVMContext &Context, const Type *RetTy) const override;

  SDValue LowerReturn(SDValue Chain, CallingConv::ID CallConv, bool isVarArg,
                      const SmallVectorImpl<ISD::OutputArg> &Outs,
                      const SmallVectorImpl<SDValue> &OutVals, const SDLoc &dl,
                      SelectionDAG &DAG) const override;

  SDValue LowerCallResult(SDValue Chain, SDValue InGlue,
                          CallingConv::ID CallConv, bool isVarArg,
                          const SmallVectorImpl<ISD::InputArg> &Ins,
                          const SDLoc &dl, SelectionDAG &DAG,
                          SmallVectorImpl<SDValue> &InVals) const;
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_V850_V850ISELLOWERING_H
