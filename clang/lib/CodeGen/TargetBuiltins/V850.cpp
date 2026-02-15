//===------ V850.cpp - Emit LLVM Code for V850 builtins -------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This contains code to emit V850 Builtin calls as LLVM code.
//
//===----------------------------------------------------------------------===//

#include "CodeGenFunction.h"
#include "clang/Basic/TargetBuiltins.h"
#include "llvm/IR/IntrinsicsV850.h"

using namespace clang;
using namespace CodeGen;
using namespace llvm;

Value *CodeGenFunction::EmitV850BuiltinExpr(unsigned BuiltinID,
                                            const CallExpr *E) {
  switch (BuiltinID) {
  default:
    return nullptr;

    //===--------------------------------------------------------------------===//
    // Atomic Bit Operations
    //===--------------------------------------------------------------------===//

  case V850::BI__builtin_v850_set1: {
    Value *Addr = EmitScalarExpr(E->getArg(0));
    Value *Bit = EmitScalarExpr(E->getArg(1));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_set1);
    return Builder.CreateCall(F, {Addr, Bit});
  }
  case V850::BI__builtin_v850_clr1: {
    Value *Addr = EmitScalarExpr(E->getArg(0));
    Value *Bit = EmitScalarExpr(E->getArg(1));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_clr1);
    return Builder.CreateCall(F, {Addr, Bit});
  }
  case V850::BI__builtin_v850_not1: {
    Value *Addr = EmitScalarExpr(E->getArg(0));
    Value *Bit = EmitScalarExpr(E->getArg(1));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_not1);
    return Builder.CreateCall(F, {Addr, Bit});
  }
  case V850::BI__builtin_v850_tst1: {
    Value *Addr = EmitScalarExpr(E->getArg(0));
    Value *Bit = EmitScalarExpr(E->getArg(1));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_tst1);
    return Builder.CreateCall(F, {Addr, Bit});
  }

    //===--------------------------------------------------------------------===//
    // Byte/Halfword Swap Operations
    //===--------------------------------------------------------------------===//

  case V850::BI__builtin_v850_hsw: {
    Value *X = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_hsw);
    return Builder.CreateCall(F, X);
  }
  case V850::BI__builtin_v850_bsh: {
    Value *X = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_bsh);
    return Builder.CreateCall(F, X);
  }
  case V850::BI__builtin_v850_hsh: {
    Value *X = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_hsh);
    return Builder.CreateCall(F, X);
  }

    //===--------------------------------------------------------------------===//
    // Memory Barrier Operations
    //===--------------------------------------------------------------------===//

  case V850::BI__builtin_v850_syncp: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_syncp);
    return Builder.CreateCall(F);
  }
  case V850::BI__builtin_v850_syncm: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_syncm);
    return Builder.CreateCall(F);
  }
  case V850::BI__builtin_v850_synce: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_synce);
    return Builder.CreateCall(F);
  }

    //===--------------------------------------------------------------------===//
    // Interrupt Control Operations
    //===--------------------------------------------------------------------===//

  case V850::BI__builtin_v850_di: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_di);
    return Builder.CreateCall(F);
  }
  case V850::BI__builtin_v850_ei: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ei);
    return Builder.CreateCall(F);
  }

    //===--------------------------------------------------------------------===//
    // Special Instructions
    //===--------------------------------------------------------------------===//

  case V850::BI__builtin_v850_halt: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_halt);
    return Builder.CreateCall(F);
  }
  case V850::BI__builtin_v850_trap: {
    Value *Vector = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_trap);
    return Builder.CreateCall(F, Vector);
  }
  case V850::BI__builtin_v850_syscall: {
    Value *Vector = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_syscall);
    return Builder.CreateCall(F, Vector);
  }
  case V850::BI__builtin_v850_fetrap: {
    Value *Vector = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_fetrap);
    return Builder.CreateCall(F, Vector);
  }
  case V850::BI__builtin_v850_dbtrap: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_dbtrap);
    return Builder.CreateCall(F);
  }

    //===--------------------------------------------------------------------===//
    // System Register Access
    //===--------------------------------------------------------------------===//

  case V850::BI__builtin_v850_ldsr: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Value *RegID = EmitScalarExpr(E->getArg(1));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr);
    return Builder.CreateCall(F, {Val, RegID});
  }
  case V850::BI__builtin_v850_stsr: {
    Value *RegID = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr);
    return Builder.CreateCall(F, RegID);
  }

  //===--------------------------------------------------------------------===//
  // Named System Register Access (Base V850)
  //===--------------------------------------------------------------------===//

  // EIPC - Exception/Interrupt saved PC (regID 0)
  case V850::BI__builtin_v850_read_eipc: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr);
    return Builder.CreateCall(F, Builder.getInt32(0));
  }
  case V850::BI__builtin_v850_write_eipc: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr);
    return Builder.CreateCall(F, {Val, Builder.getInt32(0)});
  }

  // EIPSW - Exception/Interrupt saved PSW (regID 1)
  case V850::BI__builtin_v850_read_eipsw: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr);
    return Builder.CreateCall(F, Builder.getInt32(1));
  }
  case V850::BI__builtin_v850_write_eipsw: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr);
    return Builder.CreateCall(F, {Val, Builder.getInt32(1)});
  }

  // FEPC - Fatal Error saved PC (regID 2)
  case V850::BI__builtin_v850_read_fepc: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr);
    return Builder.CreateCall(F, Builder.getInt32(2));
  }
  case V850::BI__builtin_v850_write_fepc: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr);
    return Builder.CreateCall(F, {Val, Builder.getInt32(2)});
  }

  // FEPSW - Fatal Error saved PSW (regID 3)
  case V850::BI__builtin_v850_read_fepsw: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr);
    return Builder.CreateCall(F, Builder.getInt32(3));
  }
  case V850::BI__builtin_v850_write_fepsw: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr);
    return Builder.CreateCall(F, {Val, Builder.getInt32(3)});
  }

  // ECR - Exception Cause Register (regID 4, read-only)
  case V850::BI__builtin_v850_read_ecr: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr);
    return Builder.CreateCall(F, Builder.getInt32(4));
  }

  // PSW - Program Status Word (regID 5)
  case V850::BI__builtin_v850_read_psw: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr);
    return Builder.CreateCall(F, Builder.getInt32(5));
  }
  case V850::BI__builtin_v850_write_psw: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr);
    return Builder.CreateCall(F, {Val, Builder.getInt32(5)});
  }

  //===--------------------------------------------------------------------===//
  // Named System Register Access (V850E1+)
  //===--------------------------------------------------------------------===//

  // CTPC - CALLT saved PC (regID 16)
  case V850::BI__builtin_v850_read_ctpc: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr);
    return Builder.CreateCall(F, Builder.getInt32(16));
  }
  case V850::BI__builtin_v850_write_ctpc: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr);
    return Builder.CreateCall(F, {Val, Builder.getInt32(16)});
  }

  // CTPSW - CALLT saved PSW (regID 17)
  case V850::BI__builtin_v850_read_ctpsw: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr);
    return Builder.CreateCall(F, Builder.getInt32(17));
  }
  case V850::BI__builtin_v850_write_ctpsw: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr);
    return Builder.CreateCall(F, {Val, Builder.getInt32(17)});
  }

  // CTBP - CALLT Base Pointer (regID 20)
  case V850::BI__builtin_v850_read_ctbp: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr);
    return Builder.CreateCall(F, Builder.getInt32(20));
  }
  case V850::BI__builtin_v850_write_ctbp: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr);
    return Builder.CreateCall(F, {Val, Builder.getInt32(20)});
  }

  //===--------------------------------------------------------------------===//
  // Named Debug System Register Access (V850E1+)
  //===--------------------------------------------------------------------===//

  // DBPC - Debug saved PC (regID 18)
  case V850::BI__builtin_v850_read_dbpc: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr);
    return Builder.CreateCall(F, Builder.getInt32(18));
  }
  case V850::BI__builtin_v850_write_dbpc: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr);
    return Builder.CreateCall(F, {Val, Builder.getInt32(18)});
  }

  // DBPSW - Debug saved PSW (regID 19)
  case V850::BI__builtin_v850_read_dbpsw: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr);
    return Builder.CreateCall(F, Builder.getInt32(19));
  }
  case V850::BI__builtin_v850_write_dbpsw: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr);
    return Builder.CreateCall(F, {Val, Builder.getInt32(19)});
  }

  // DIR - Debug Interface Register (regID 21)
  case V850::BI__builtin_v850_read_dir: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr);
    return Builder.CreateCall(F, Builder.getInt32(21));
  }
  case V850::BI__builtin_v850_write_dir: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr);
    return Builder.CreateCall(F, {Val, Builder.getInt32(21)});
  }

  // Select breakpoint channel (0 or 1) via DIR.CS bit (bit 0)
  // Performs read-modify-write on DIR register
  case V850::BI__builtin_v850_select_bp_channel: {
    Value *Channel = EmitScalarExpr(E->getArg(0));
    Function *ReadF = CGM.getIntrinsic(Intrinsic::v850_stsr);
    Function *WriteF = CGM.getIntrinsic(Intrinsic::v850_ldsr);

    // Read current DIR value
    Value *Dir = Builder.CreateCall(ReadF, Builder.getInt32(21));

    // Compare channel with 0
    Value *IsZero = Builder.CreateICmpEQ(Channel, Builder.getInt32(0));

    // Clear bit 0: Dir & ~1
    Value *Cleared = Builder.CreateAnd(Dir, Builder.getInt32(~1U));
    // Set bit 0: Dir | 1
    Value *Set = Builder.CreateOr(Dir, Builder.getInt32(1));

    // Select based on channel: if channel == 0, use cleared, else use set
    Value *NewDir = Builder.CreateSelect(IsZero, Cleared, Set);

    // Write back to DIR
    return Builder.CreateCall(WriteF, {NewDir, Builder.getInt32(21)});
  }

  // BPC - Breakpoint Control (regID 22)
  case V850::BI__builtin_v850_read_bpc: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr);
    return Builder.CreateCall(F, Builder.getInt32(22));
  }
  case V850::BI__builtin_v850_write_bpc: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr);
    return Builder.CreateCall(F, {Val, Builder.getInt32(22)});
  }

  // ASID - Address Space ID (regID 23)
  case V850::BI__builtin_v850_read_asid: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr);
    return Builder.CreateCall(F, Builder.getInt32(23));
  }
  case V850::BI__builtin_v850_write_asid: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr);
    return Builder.CreateCall(F, {Val, Builder.getInt32(23)});
  }

  // BPAV - Breakpoint Address Value (regID 24)
  case V850::BI__builtin_v850_read_bpav: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr);
    return Builder.CreateCall(F, Builder.getInt32(24));
  }
  case V850::BI__builtin_v850_write_bpav: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr);
    return Builder.CreateCall(F, {Val, Builder.getInt32(24)});
  }

  // BPAM - Breakpoint Address Mask (regID 25)
  case V850::BI__builtin_v850_read_bpam: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr);
    return Builder.CreateCall(F, Builder.getInt32(25));
  }
  case V850::BI__builtin_v850_write_bpam: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr);
    return Builder.CreateCall(F, {Val, Builder.getInt32(25)});
  }

  // BPDV - Breakpoint Data Value (regID 26)
  case V850::BI__builtin_v850_read_bpdv: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr);
    return Builder.CreateCall(F, Builder.getInt32(26));
  }
  case V850::BI__builtin_v850_write_bpdv: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr);
    return Builder.CreateCall(F, {Val, Builder.getInt32(26)});
  }

  // BPDM - Breakpoint Data Mask (regID 27)
  case V850::BI__builtin_v850_read_bpdm: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr);
    return Builder.CreateCall(F, Builder.getInt32(27));
  }
  case V850::BI__builtin_v850_write_bpdm: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr);
    return Builder.CreateCall(F, {Val, Builder.getInt32(27)});
  }

  //===--------------------------------------------------------------------===//
  // Named Exception Cause Register Access (V850E2+)
  //===--------------------------------------------------------------------===//

  // EIIC - EI Exception Cause (regID 13)
  case V850::BI__builtin_v850_read_eiic: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr);
    return Builder.CreateCall(F, Builder.getInt32(13));
  }
  case V850::BI__builtin_v850_write_eiic: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr);
    return Builder.CreateCall(F, {Val, Builder.getInt32(13)});
  }

  // FEIC - FE Exception Cause (regID 14)
  case V850::BI__builtin_v850_read_feic: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr);
    return Builder.CreateCall(F, Builder.getInt32(14));
  }
  case V850::BI__builtin_v850_write_feic: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr);
    return Builder.CreateCall(F, {Val, Builder.getInt32(14)});
  }

  //===--------------------------------------------------------------------===//
  // Named System Register Access (V850E2M+)
  //===--------------------------------------------------------------------===//

  // EIWR - EI-level Working Register (regID 28)
  case V850::BI__builtin_v850_read_eiwr: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr);
    return Builder.CreateCall(F, Builder.getInt32(28));
  }
  case V850::BI__builtin_v850_write_eiwr: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr);
    return Builder.CreateCall(F, {Val, Builder.getInt32(28)});
  }

  // FEWR - FE-level Working Register (regID 29)
  case V850::BI__builtin_v850_read_fewr: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr);
    return Builder.CreateCall(F, Builder.getInt32(29));
  }
  case V850::BI__builtin_v850_write_fewr: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr);
    return Builder.CreateCall(F, {Val, Builder.getInt32(29)});
  }

  // DBWR - Debug Working Register (regID 30)
  case V850::BI__builtin_v850_read_dbwr: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr);
    return Builder.CreateCall(F, Builder.getInt32(30));
  }
  case V850::BI__builtin_v850_write_dbwr: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr);
    return Builder.CreateCall(F, {Val, Builder.getInt32(30)});
  }

  // BSEL - Bank Selection Register (regID 31)
  case V850::BI__builtin_v850_read_bsel: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr);
    return Builder.CreateCall(F, Builder.getInt32(31));
  }
  case V850::BI__builtin_v850_write_bsel: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr);
    return Builder.CreateCall(F, {Val, Builder.getInt32(31)});
  }

    //===--------------------------------------------------------------------===//
    // Saturating Arithmetic Operations
    //===--------------------------------------------------------------------===//

  case V850::BI__builtin_v850_satadd: {
    Value *A = EmitScalarExpr(E->getArg(0));
    Value *B = EmitScalarExpr(E->getArg(1));
    // Use LLVM's saturating add intrinsic
    Function *F = CGM.getIntrinsic(Intrinsic::sadd_sat, {Int32Ty});
    return Builder.CreateCall(F, {A, B});
  }
  case V850::BI__builtin_v850_satsub: {
    Value *A = EmitScalarExpr(E->getArg(0));
    Value *B = EmitScalarExpr(E->getArg(1));
    // Use LLVM's saturating sub intrinsic
    Function *F = CGM.getIntrinsic(Intrinsic::ssub_sat, {Int32Ty});
    return Builder.CreateCall(F, {A, B});
  }
  case V850::BI__builtin_v850_satsubr: {
    Value *A = EmitScalarExpr(E->getArg(0));
    Value *B = EmitScalarExpr(E->getArg(1));
    // Use V850 SATSUBR intrinsic: saturate(a - b)
    Function *F = CGM.getIntrinsic(Intrinsic::v850_satsubr);
    return Builder.CreateCall(F, {A, B});
  }
  case V850::BI__builtin_v850_satadd3: {
    Value *A = EmitScalarExpr(E->getArg(0));
    Value *B = EmitScalarExpr(E->getArg(1));
    // Use V850 SATADD3 intrinsic for 3-operand form
    Function *F = CGM.getIntrinsic(Intrinsic::v850_satadd3);
    return Builder.CreateCall(F, {A, B});
  }
  case V850::BI__builtin_v850_satsub3: {
    Value *A = EmitScalarExpr(E->getArg(0));
    Value *B = EmitScalarExpr(E->getArg(1));
    // Use V850 SATSUB3 intrinsic for 3-operand form
    Function *F = CGM.getIntrinsic(Intrinsic::v850_satsub3);
    return Builder.CreateCall(F, {A, B});
  }

    //===--------------------------------------------------------------------===//
    // Bit Search Operations (V850E2+)
    //===--------------------------------------------------------------------===//

  case V850::BI__builtin_v850_sch1l: {
    Value *X = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_sch1l);
    return Builder.CreateCall(F, X);
  }
  case V850::BI__builtin_v850_sch1r: {
    Value *X = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_sch1r);
    return Builder.CreateCall(F, X);
  }
  case V850::BI__builtin_v850_sch0l: {
    Value *X = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_sch0l);
    return Builder.CreateCall(F, X);
  }
  case V850::BI__builtin_v850_sch0r: {
    Value *X = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_sch0r);
    return Builder.CreateCall(F, X);
  }

    //===--------------------------------------------------------------------===//
    // Atomic Operations (V850E2M+)
    //===--------------------------------------------------------------------===//

  case V850::BI__builtin_v850_caxi: {
    Value *Addr = EmitScalarExpr(E->getArg(0));
    Value *Expected = EmitScalarExpr(E->getArg(1));
    Value *Desired = EmitScalarExpr(E->getArg(2));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_caxi);
    return Builder.CreateCall(F, {Addr, Expected, Desired});
  }

    //===--------------------------------------------------------------------===//
    // Multiply-Accumulate Operations (V850E1+)
    //===--------------------------------------------------------------------===//

  case V850::BI__builtin_v850_mac: {
    // long long __builtin_v850_mac(int a, int b, long long acc)
    Value *A = EmitScalarExpr(E->getArg(0));
    Value *B = EmitScalarExpr(E->getArg(1));
    Value *Acc = EmitScalarExpr(E->getArg(2));
    // Split 64-bit acc into hi and lo parts
    Value *AccLo = Builder.CreateTrunc(Acc, Int32Ty);
    Value *AccHi = Builder.CreateTrunc(Builder.CreateLShr(Acc, 32), Int32Ty);
    // Call the intrinsic
    Function *F = CGM.getIntrinsic(Intrinsic::v850_mac);
    Value *Result = Builder.CreateCall(F, {A, B, AccHi, AccLo});
    // Extract hi and lo results and combine into 64-bit value
    Value *ResHi = Builder.CreateExtractValue(Result, 0);
    Value *ResLo = Builder.CreateExtractValue(Result, 1);
    Value *ResHi64 = Builder.CreateZExt(ResHi, Int64Ty);
    Value *ResLo64 = Builder.CreateZExt(ResLo, Int64Ty);
    return Builder.CreateOr(Builder.CreateShl(ResHi64, 32), ResLo64);
  }
  case V850::BI__builtin_v850_macu: {
    // unsigned long long __builtin_v850_macu(unsigned int a, unsigned int b,
    //                                        unsigned long long acc)
    Value *A = EmitScalarExpr(E->getArg(0));
    Value *B = EmitScalarExpr(E->getArg(1));
    Value *Acc = EmitScalarExpr(E->getArg(2));
    // Split 64-bit acc into hi and lo parts
    Value *AccLo = Builder.CreateTrunc(Acc, Int32Ty);
    Value *AccHi = Builder.CreateTrunc(Builder.CreateLShr(Acc, 32), Int32Ty);
    // Call the intrinsic
    Function *F = CGM.getIntrinsic(Intrinsic::v850_macu);
    Value *Result = Builder.CreateCall(F, {A, B, AccHi, AccLo});
    // Extract hi and lo results and combine into 64-bit value
    Value *ResHi = Builder.CreateExtractValue(Result, 0);
    Value *ResLo = Builder.CreateExtractValue(Result, 1);
    Value *ResHi64 = Builder.CreateZExt(ResHi, Int64Ty);
    Value *ResLo64 = Builder.CreateZExt(ResLo, Int64Ty);
    return Builder.CreateOr(Builder.CreateShl(ResHi64, 32), ResLo64);
  }

    //===--------------------------------------------------------------------===//
    // FPU System Register Access (V850E2M+)
    //===--------------------------------------------------------------------===//

  case V850::BI__builtin_v850_read_fpsr: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_read_fpsr);
    return Builder.CreateCall(F);
  }
  case V850::BI__builtin_v850_read_fpepc: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_read_fpepc);
    return Builder.CreateCall(F);
  }
  case V850::BI__builtin_v850_read_fpst: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_read_fpst);
    return Builder.CreateCall(F);
  }
  case V850::BI__builtin_v850_read_fpcc: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_read_fpcc);
    return Builder.CreateCall(F);
  }
  case V850::BI__builtin_v850_read_fpcfg: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_read_fpcfg);
    return Builder.CreateCall(F);
  }
  case V850::BI__builtin_v850_read_fpec: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_read_fpec);
    return Builder.CreateCall(F);
  }
  case V850::BI__builtin_v850_write_fpsr: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_write_fpsr);
    return Builder.CreateCall(F, Val);
  }
  case V850::BI__builtin_v850_write_fpepc: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_write_fpepc);
    return Builder.CreateCall(F, Val);
  }
  case V850::BI__builtin_v850_write_fpst: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_write_fpst);
    return Builder.CreateCall(F, Val);
  }
  case V850::BI__builtin_v850_write_fpcc: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_write_fpcc);
    return Builder.CreateCall(F, Val);
  }
  case V850::BI__builtin_v850_write_fpcfg: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_write_fpcfg);
    return Builder.CreateCall(F, Val);
  }
  case V850::BI__builtin_v850_write_fpec: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_write_fpec);
    return Builder.CreateCall(F, Val);
  }

    //===--------------------------------------------------------------------===//
    // RH850G3M Instructions
    //===--------------------------------------------------------------------===//

  case V850::BI__builtin_v850_synci: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_synci);
    return Builder.CreateCall(F);
  }
  case V850::BI__builtin_v850_snooze: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_snooze);
    return Builder.CreateCall(F);
  }
  case V850::BI__builtin_v850_cll: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_cll);
    return Builder.CreateCall(F);
  }
  case V850::BI__builtin_v850_ldl_w: {
    Value *Addr = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldl_w);
    return Builder.CreateCall(F, Addr);
  }
  case V850::BI__builtin_v850_stc_w: {
    Value *Addr = EmitScalarExpr(E->getArg(0));
    Value *Val = EmitScalarExpr(E->getArg(1));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stc_w);
    return Builder.CreateCall(F, {Addr, Val});
  }
  case V850::BI__builtin_v850_cache: {
    Value *CacheOp = EmitScalarExpr(E->getArg(0));
    Value *Addr = EmitScalarExpr(E->getArg(1));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_cache);
    return Builder.CreateCall(F, {CacheOp, Addr});
  }
  case V850::BI__builtin_v850_pref: {
    Value *PrefOp = EmitScalarExpr(E->getArg(0));
    Value *Addr = EmitScalarExpr(E->getArg(1));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_pref);
    return Builder.CreateCall(F, {PrefOp, Addr});
  }
  case V850::BI__builtin_v850_bins: {
    Value *Dst = EmitScalarExpr(E->getArg(0));
    Value *Src = EmitScalarExpr(E->getArg(1));
    Value *Pos = EmitScalarExpr(E->getArg(2));
    Value *Width = EmitScalarExpr(E->getArg(3));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_bins);
    return Builder.CreateCall(F, {Dst, Src, Pos, Width});
  }
  case V850::BI__builtin_v850_ldsr_group: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Value *RegID = EmitScalarExpr(E->getArg(1));
    Value *SelID = EmitScalarExpr(E->getArg(2));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr_sel);
    return Builder.CreateCall(F, {Val, RegID, SelID});
  }
  case V850::BI__builtin_v850_stsr_group: {
    Value *RegID = EmitScalarExpr(E->getArg(0));
    Value *SelID = EmitScalarExpr(E->getArg(1));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr_sel);
    return Builder.CreateCall(F, {RegID, SelID});
  }

  //===--------------------------------------------------------------------===//
  // Named G3M System Register Access (Groups 1-2)
  //===--------------------------------------------------------------------===//

  // --- Group 1: Machine Configuration ---

  // RBASE - Reset vector base (regID=2, selID=1)
  case V850::BI__builtin_v850_read_rbase: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr_sel);
    return Builder.CreateCall(F, {Builder.getInt32(2), Builder.getInt32(1)});
  }
  case V850::BI__builtin_v850_write_rbase: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr_sel);
    return Builder.CreateCall(F,
                              {Val, Builder.getInt32(2), Builder.getInt32(1)});
  }

  // EBASE - Exception handler vector base (regID=3, selID=1)
  case V850::BI__builtin_v850_read_ebase: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr_sel);
    return Builder.CreateCall(F, {Builder.getInt32(3), Builder.getInt32(1)});
  }
  case V850::BI__builtin_v850_write_ebase: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr_sel);
    return Builder.CreateCall(F,
                              {Val, Builder.getInt32(3), Builder.getInt32(1)});
  }

  // INTBP - Interrupt handler table base (regID=4, selID=1)
  case V850::BI__builtin_v850_read_intbp: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr_sel);
    return Builder.CreateCall(F, {Builder.getInt32(4), Builder.getInt32(1)});
  }
  case V850::BI__builtin_v850_write_intbp: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr_sel);
    return Builder.CreateCall(F,
                              {Val, Builder.getInt32(4), Builder.getInt32(1)});
  }

  // SCBP - SYSCALL base pointer (regID=12, selID=1)
  case V850::BI__builtin_v850_read_scbp: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr_sel);
    return Builder.CreateCall(F, {Builder.getInt32(12), Builder.getInt32(1)});
  }
  case V850::BI__builtin_v850_write_scbp: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr_sel);
    return Builder.CreateCall(F,
                              {Val, Builder.getInt32(12), Builder.getInt32(1)});
  }

  // --- Group 2: Thread/Interrupt ---

  // MEA - Memory error address (regID=6, selID=2)
  case V850::BI__builtin_v850_read_mea: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr_sel);
    return Builder.CreateCall(F, {Builder.getInt32(6), Builder.getInt32(2)});
  }
  case V850::BI__builtin_v850_write_mea: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr_sel);
    return Builder.CreateCall(F,
                              {Val, Builder.getInt32(6), Builder.getInt32(2)});
  }

  // MEI - Memory error information (regID=8, selID=2)
  case V850::BI__builtin_v850_read_mei: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr_sel);
    return Builder.CreateCall(F, {Builder.getInt32(8), Builder.getInt32(2)});
  }
  case V850::BI__builtin_v850_write_mei: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr_sel);
    return Builder.CreateCall(F,
                              {Val, Builder.getInt32(8), Builder.getInt32(2)});
  }

  // ISPR - Interrupt priority register (regID=10, selID=2)
  case V850::BI__builtin_v850_read_ispr: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr_sel);
    return Builder.CreateCall(F, {Builder.getInt32(10), Builder.getInt32(2)});
  }
  case V850::BI__builtin_v850_write_ispr: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr_sel);
    return Builder.CreateCall(F,
                              {Val, Builder.getInt32(10), Builder.getInt32(2)});
  }

  // PMR - Interrupt priority masking (regID=11, selID=2)
  case V850::BI__builtin_v850_read_pmr: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr_sel);
    return Builder.CreateCall(F, {Builder.getInt32(11), Builder.getInt32(2)});
  }
  case V850::BI__builtin_v850_write_pmr: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr_sel);
    return Builder.CreateCall(F,
                              {Val, Builder.getInt32(11), Builder.getInt32(2)});
  }

  // ICSR - Interrupt control status (regID=12, selID=2, read-only)
  case V850::BI__builtin_v850_read_icsr: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr_sel);
    return Builder.CreateCall(F, {Builder.getInt32(12), Builder.getInt32(2)});
  }

  // INTCFG - Interrupt function setting (regID=13, selID=2)
  case V850::BI__builtin_v850_read_intcfg: {
    Function *F = CGM.getIntrinsic(Intrinsic::v850_stsr_sel);
    return Builder.CreateCall(F, {Builder.getInt32(13), Builder.getInt32(2)});
  }
  case V850::BI__builtin_v850_write_intcfg: {
    Value *Val = EmitScalarExpr(E->getArg(0));
    Function *F = CGM.getIntrinsic(Intrinsic::v850_ldsr_sel);
    return Builder.CreateCall(F,
                              {Val, Builder.getInt32(13), Builder.getInt32(2)});
  }
  }
}
