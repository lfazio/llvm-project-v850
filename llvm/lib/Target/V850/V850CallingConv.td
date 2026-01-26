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
// - Callee-saved: r20-r31 (r29=FP, r30=EP, r31=LP)
// - Caller-saved: r1, r6-r19
// - Stack alignment: 4 bytes
// - i64/f64 passed in even:odd register pairs (r6:r7, r8:r9)
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// V850 Argument Calling Convention
//===----------------------------------------------------------------------===//

def CC_V850 : CallingConv<[
  // Handle sret (struct return pointer) - passed in r6
  CCIfSRet<CCIfType<[i32], CCAssignToReg<[R6]>>>,

  // Pass by value structs with alignment 4
  CCIfByVal<CCPassByVal<4, 4>>,

  // Promote i8/i16 arguments to i32
  CCIfType<[i8, i16], CCPromoteToType<i32>>,

  // i64 values are passed in register pairs r6:r7, r8:r9 (even:odd pairs)
  // Must be before i32 to ensure proper pairing
  CCIfType<[i64], CCAssignToRegWithShadow<[R6, R8], [R7, R9]>>,

  // The first 4 words (16 bytes) are passed in r6-r9
  CCIfType<[i32], CCAssignToReg<[R6, R7, R8, R9]>>,

  // f32 values are passed in r6-r9 (same as i32, using GPRs)
  CCIfType<[f32], CCAssignToReg<[R6, R7, R8, R9]>>,

  // f64 values are passed in register pairs r6:r7, r8:r9 (even:odd pairs)
  CCIfType<[f64], CCAssignToRegWithShadow<[R6, R8], [R7, R9]>>,

  // i64 values on stack are 8-byte aligned
  CCIfType<[i64], CCAssignToStack<8, 8>>,

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

// Standard callee-saved registers: r20-r29, EP (r30), LP (r31)
// Note: r29 is used as frame pointer when needed
def CSR_V850 : CalleeSavedRegs<(add R20, R21, R22, R23, R24, R25,
                                    R26, R27, R28, R29, EP, LP)>;

// Interrupt handler callee-saved registers - must preserve ALL registers
// since we can't know what state the interrupted code was in.
// Note: r0 is zero and doesn't need saving
// R3=SP, R4=GP, R5=TP are named registers, R30=EP, R31=LP
def CSR_V850_Interrupt : CalleeSavedRegs<(add R1, R2, SP, GP, TP,
                                              R6, R7, R8, R9,
                                              R10, R11, R12, R13, R14, R15,
                                              R16, R17, R18, R19,
                                              R20, R21, R22, R23, R24, R25,
                                              R26, R27, R28, R29, EP, LP)>;

// No callee-saved registers for functions that don't return (noreturn)
def CSR_V850_NoRegs : CalleeSavedRegs<(add)>;
