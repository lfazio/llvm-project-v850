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
#include "V850.h"
#include "V850RegisterInfo.h"
#include "V850Subtarget.h"
#include "V850TargetMachine.h"
#include "llvm/CodeGen/CallingConvLower.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/IR/CallingConv.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
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

  // V850E2M has FPU - use FPR class for floating-point
  // (FPR uses same physical registers as GPR but for f32 type)
  if (STI.hasV850E2M()) {
    addRegisterClass(MVT::f32, &V850::FPRRegClass);
    // f64 uses register pairs, will be expanded to library calls
  }

  // Compute derived properties from the register classes
  computeRegisterProperties(STI.getRegisterInfo());

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
    // Base V850 uses library calls
    setOperationAction(ISD::MUL, MVT::i32, Expand);
    setOperationAction(ISD::MULHS, MVT::i32, Expand);
    setOperationAction(ISD::MULHU, MVT::i32, Expand);
    setOperationAction(ISD::SMUL_LOHI, MVT::i32, Expand);
    setOperationAction(ISD::UMUL_LOHI, MVT::i32, Expand);
  }

  // Rotates - expand
  setOperationAction(ISD::ROTL, MVT::i32, Expand);
  setOperationAction(ISD::ROTR, MVT::i32, Expand);

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
  setOperationAction(ISD::BSWAP, MVT::i32, Legal);  // V850 has BSW instruction
  setOperationAction(ISD::BITREVERSE, MVT::i32, Expand);

  // Sign extension in register - V850 has SXB and SXH instructions
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i1, Expand);
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i8, Legal);
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i16, Legal);

  // Expand SELECT to SELECT_CC
  setOperationAction(ISD::SELECT, MVT::i32, Expand);
  setOperationAction(ISD::SELECT_CC, MVT::i32, Custom);

  // Custom lowering for branch conditions
  setOperationAction(ISD::BR_CC, MVT::i32, Custom);
  setOperationAction(ISD::BRCOND, MVT::Other, Expand);

  // Global addresses
  setOperationAction(ISD::GlobalAddress, MVT::i32, Custom);
  setOperationAction(ISD::ExternalSymbol, MVT::i32, Custom);
  setOperationAction(ISD::BlockAddress, MVT::i32, Custom);

  // Jump table
  setOperationAction(ISD::BR_JT, MVT::Other, Expand);

  // VAARG support - expand
  setOperationAction(ISD::VASTART, MVT::Other, Expand);
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

  // Atomics - not supported, expand
  setMaxAtomicSizeInBitsSupported(0);

  // FPU operations for V850E2M
  if (STI.hasV850E2M()) {
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

    // Comparisons - expand to library calls (complex FP compare status handling)
    setOperationAction(ISD::SETCC, MVT::f32, Expand);
    setOperationAction(ISD::SELECT_CC, MVT::f32, Expand);
    setOperationAction(ISD::BR_CC, MVT::f32, Expand);

    // Double-precision - expand to library calls for now
    // (would need register pair handling for hardware support)
    setOperationAction(ISD::FADD, MVT::f64, Expand);
    setOperationAction(ISD::FSUB, MVT::f64, Expand);
    setOperationAction(ISD::FMUL, MVT::f64, Expand);
    setOperationAction(ISD::FDIV, MVT::f64, Expand);
    setOperationAction(ISD::FABS, MVT::f64, Expand);
    setOperationAction(ISD::FNEG, MVT::f64, Expand);
    setOperationAction(ISD::FSQRT, MVT::f64, Expand);
    setOperationAction(ISD::FP_EXTEND, MVT::f64, Expand);
    setOperationAction(ISD::FP_ROUND, MVT::f32, Expand);

    // Bitcast between i32 and f32
    setOperationAction(ISD::BITCAST, MVT::i32, Legal);
    setOperationAction(ISD::BITCAST, MVT::f32, Legal);
  }

  // Set minimum function alignment
  setMinFunctionAlignment(Align(2));
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
  case V850ISD::WRAPPER:
    return "V850ISD::WRAPPER";
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
  case V850ISD::SDIVREM:
    return "V850ISD::SDIVREM";
  case V850ISD::UDIVREM:
    return "V850ISD::UDIVREM";
  }
  return nullptr;
}

SDValue V850TargetLowering::LowerGlobalAddress(SDValue Op,
                                               SelectionDAG &DAG) const {
  SDLoc DL(Op);
  EVT VT = Op.getValueType();
  const GlobalValue *GV = cast<GlobalAddressSDNode>(Op)->getGlobal();
  int64_t Offset = cast<GlobalAddressSDNode>(Op)->getOffset();

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

SDValue V850TargetLowering::LowerBR_CC(SDValue Op, SelectionDAG &DAG) const {
  SDValue Chain = Op.getOperand(0);
  ISD::CondCode CC = cast<CondCodeSDNode>(Op.getOperand(1))->get();
  SDValue LHS = Op.getOperand(2);
  SDValue RHS = Op.getOperand(3);
  SDValue Dest = Op.getOperand(4);
  SDLoc DL(Op);

  SDValue Cmp = DAG.getNode(V850ISD::CMP, DL, MVT::Glue, LHS, RHS);
  return DAG.getNode(V850ISD::BR_CC, DL, Op.getValueType(), Chain, Dest,
                     DAG.getConstant(CC, DL, MVT::i32), Cmp);
}

SDValue V850TargetLowering::LowerSELECT_CC(SDValue Op, SelectionDAG &DAG) const {
  SDValue LHS = Op.getOperand(0);
  SDValue RHS = Op.getOperand(1);
  SDValue TrueV = Op.getOperand(2);
  SDValue FalseV = Op.getOperand(3);
  ISD::CondCode CC = cast<CondCodeSDNode>(Op.getOperand(4))->get();
  SDLoc DL(Op);

  SDValue Cmp = DAG.getNode(V850ISD::CMP, DL, MVT::Glue, LHS, RHS);
  return DAG.getNode(V850ISD::SELECT_CC, DL, Op.getValueType(), TrueV, FalseV,
                     DAG.getConstant(CC, DL, MVT::i32), Cmp);
}

SDValue V850TargetLowering::LowerMUL(SDValue Op, SelectionDAG &DAG) const {
  // V850's MUL instruction produces a 64-bit result in two registers.
  // For simple 32-bit multiply, we use V850ISD::SMUL and take only the low part.
  SDLoc DL(Op);
  SDValue LHS = Op.getOperand(0);
  SDValue RHS = Op.getOperand(1);

  // V850ISD::SMUL returns (low, high)
  SDValue MulLoHi =
      DAG.getNode(V850ISD::SMUL, DL, DAG.getVTList(MVT::i32, MVT::i32), LHS, RHS);
  return MulLoHi.getValue(0); // Return the low 32 bits
}

SDValue V850TargetLowering::LowerMULHS(SDValue Op, SelectionDAG &DAG) const {
  // MULHS needs the high 32 bits of signed multiply
  SDLoc DL(Op);
  SDValue LHS = Op.getOperand(0);
  SDValue RHS = Op.getOperand(1);

  // V850ISD::SMUL returns (low, high)
  SDValue MulLoHi =
      DAG.getNode(V850ISD::SMUL, DL, DAG.getVTList(MVT::i32, MVT::i32), LHS, RHS);
  return MulLoHi.getValue(1); // Return the high 32 bits
}

SDValue V850TargetLowering::LowerMULHU(SDValue Op, SelectionDAG &DAG) const {
  // MULHU needs the high 32 bits of unsigned multiply
  SDLoc DL(Op);
  SDValue LHS = Op.getOperand(0);
  SDValue RHS = Op.getOperand(1);

  // V850ISD::UMUL returns (low, high)
  SDValue MulLoHi =
      DAG.getNode(V850ISD::UMUL, DL, DAG.getVTList(MVT::i32, MVT::i32), LHS, RHS);
  return MulLoHi.getValue(1); // Return the high 32 bits
}

SDValue V850TargetLowering::LowerDivRem(SDValue Op, SelectionDAG &DAG) const {
  // V850's DIV/DIVU instructions produce both quotient and remainder.
  // Convert SDIV/UDIV/SREM/UREM to V850ISD::SDIVREM/UDIVREM and extract the needed part.
  SDLoc DL(Op);
  unsigned Opcode = Op.getOpcode();
  SDValue LHS = Op.getOperand(0);
  SDValue RHS = Op.getOperand(1);

  bool IsSigned = (Opcode == ISD::SDIV || Opcode == ISD::SREM ||
                   Opcode == ISD::SDIVREM);
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

Register V850TargetLowering::getRegisterByName(const char *RegName, LLT VT,
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

  report_fatal_error(Twine("Invalid register name \"" + StringRef(RegName) + "\"."));
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
      Register VReg = RegInfo.createVirtualRegister(&V850::GPRRegClass);
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

  MachineFunction &MF = DAG.getMachineFunction();

  // Analyze operands of the call, assigning locations to each operand
  SmallVector<CCValAssign, 16> ArgLocs;
  CCState CCInfo(CallConv, isVarArg, MF, ArgLocs, *DAG.getContext());
  CCInfo.AnalyzeCallOperands(Outs, CC_V850);

  // Get the size of the outgoing arguments stack space
  unsigned NumBytes = CCInfo.getStackSize();

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

  // Add a register mask operand representing call-preserved registers
  const TargetRegisterInfo *TRI = Subtarget.getRegisterInfo();
  const uint32_t *Mask = TRI->getCallPreservedMask(MF, CallConv);
  assert(Mask && "Missing call preserved mask for calling convention");
  Ops.push_back(DAG.getRegisterMask(Mask));

  if (InGlue.getNode())
    Ops.push_back(InGlue);

  SDVTList NodeTys = DAG.getVTList(MVT::Other, MVT::Glue);
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
