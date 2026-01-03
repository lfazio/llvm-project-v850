//===- IntrinsicsV850.td - Defines V850 intrinsics ---------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines all of the V850-specific intrinsics.
//
//===----------------------------------------------------------------------===//

let TargetPrefix = "v850" in {  // All intrinsics start with "llvm.v850.".

//===----------------------------------------------------------------------===//
// Atomic Bit Manipulation Operations
// These operations atomically modify a single bit in memory.
// The address must be byte-aligned.
//===----------------------------------------------------------------------===//

// SET1 - Atomically set a bit in memory
// void @llvm.v850.set1(ptr %addr, i32 %bit)
def int_v850_set1 : Intrinsic<[], [llvm_ptr_ty, llvm_i32_ty],
                              [IntrArgMemOnly, NoCapture<ArgIndex<0>>]>;

// CLR1 - Atomically clear a bit in memory
// void @llvm.v850.clr1(ptr %addr, i32 %bit)
def int_v850_clr1 : Intrinsic<[], [llvm_ptr_ty, llvm_i32_ty],
                              [IntrArgMemOnly, NoCapture<ArgIndex<0>>]>;

// NOT1 - Atomically toggle a bit in memory
// void @llvm.v850.not1(ptr %addr, i32 %bit)
def int_v850_not1 : Intrinsic<[], [llvm_ptr_ty, llvm_i32_ty],
                              [IntrArgMemOnly, NoCapture<ArgIndex<0>>]>;

// TST1 - Test a bit in memory (sets Z flag, returns 1 if bit was 0)
// i32 @llvm.v850.tst1(ptr %addr, i32 %bit)
def int_v850_tst1 : Intrinsic<[llvm_i32_ty], [llvm_ptr_ty, llvm_i32_ty],
                              [IntrReadMem, IntrArgMemOnly, NoCapture<ArgIndex<0>>]>;

} // TargetPrefix = "v850"
