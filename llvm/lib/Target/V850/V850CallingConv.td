//===-- V850CallingConv.td - V850 Calling Conventions ------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This describes the calling conventions for the V850 architecture.
//
// V850 EABI Calling Convention:
// - Arguments: r6-r9 (first 4 words), then stack
// - Return: r10 (32-bit), r10:r11 (64-bit)
// - Callee-saved: r20-r31
// - Caller-saved: r1, r6-r19
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// V850 Argument Calling Convention
//===----------------------------------------------------------------------===//

def CC_V850 : CallingConv<[
  // Promote i8/i16 arguments to i32
  CCIfType<[i8, i16], CCPromoteToType<i32>>,

  // The first 4 words (16 bytes) are passed in r6-r9
  CCIfType<[i32], CCAssignToReg<[R6, R7, R8, R9]>>,

  // f32 values are passed in r6-r9 (same as i32, using GPRs)
  CCIfType<[f32], CCAssignToReg<[R6, R7, R8, R9]>>,

  // f64 values are passed in register pairs r6:r7, r8:r9 (even:odd pairs)
  CCIfType<[f64], CCAssignToRegWithShadow<[R6, R8], [R7, R9]>>,

  // Integer values get stored in stack slots that are 4 bytes in size and
  // 4-byte aligned
  CCIfType<[i32], CCAssignToStack<4, 4>>,

  // f32 values on stack are 4-byte aligned
  CCIfType<[f32], CCAssignToStack<4, 4>>,

  // f64 values on stack are 8-byte aligned
  CCIfType<[f64], CCAssignToStack<8, 8>>
]>;

//===----------------------------------------------------------------------===//
// V850 Return Value Calling Convention
//===----------------------------------------------------------------------===//

def RetCC_V850 : CallingConv<[
  // Promote i8/i16 return values to i32
  CCIfType<[i8, i16], CCPromoteToType<i32>>,

  // i32 values are returned in r10
  CCIfType<[i32], CCAssignToReg<[R10]>>,

  // f32 values are returned in r10 (using GPR)
  CCIfType<[f32], CCAssignToReg<[R10]>>,

  // i64 values are returned in r10:r11 (low:high)
  CCIfType<[i64], CCAssignToRegWithShadow<[R10], [R11]>>,

  // f64 values are returned in r10:r11 (low:high pair)
  CCIfType<[f64], CCAssignToRegWithShadow<[R10], [R11]>>
]>;

//===----------------------------------------------------------------------===//
// Callee-saved Registers
//===----------------------------------------------------------------------===//

def CSR_V850 : CalleeSavedRegs<(add R20, R21, R22, R23, R24, R25,
                                    R26, R27, R28, R29, EP, LP)>;
