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

let TargetPrefix = "v850" in { // All intrinsics start with "llvm.v850.".

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
  def int_v850_tst1
      : Intrinsic<[llvm_i32_ty], [llvm_ptr_ty, llvm_i32_ty],
                  [IntrReadMem, IntrArgMemOnly, NoCapture<ArgIndex<0>>]>;

  //===----------------------------------------------------------------------===//
  // Byte/Halfword Swap Operations
  //===----------------------------------------------------------------------===//

  // HSW - Halfword swap (swap upper and lower 16-bit halfwords)
  // i32 @llvm.v850.hsw(i32 %x)
  // Result: (x >> 16) | (x << 16), i.e., 0xAABBCCDD -> 0xCCDDAABB
  def int_v850_hsw : Intrinsic<[llvm_i32_ty], [llvm_i32_ty],
                               [IntrNoMem, IntrSpeculatable, IntrWillReturn]>;

  // BSH - Byte swap halfword (swap bytes in lower 16 bits, keep upper
  // unchanged) i32 @llvm.v850.bsh(i32 %x) Result: 0xAABBCCDD -> 0xAABBDDCC
  def int_v850_bsh : Intrinsic<[llvm_i32_ty], [llvm_i32_ty],
                               [IntrNoMem, IntrSpeculatable, IntrWillReturn]>;

  //===----------------------------------------------------------------------===//
  // FPU System Register Access (V850E2M+)
  //
  // These intrinsics provide access to FPU system registers via BSEL banking.
  // On V850E2M, FPU registers (regID 6-11) are only accessible when
  // BSEL=0x2000. These intrinsics automatically handle the BSEL register
  // switching sequence:
  //   1. Set BSEL to 0x2000 (FPU Status Bank)
  //   2. Access the FPU register via LDSR/STSR
  //   3. Restore BSEL to 0x0000 (CPU Main Bank)
  //===----------------------------------------------------------------------===//

  // Read FPU status registers
  // i32 @llvm.v850.read.fpsr() - Read FPSR (regID 6)
  def int_v850_read_fpsr
      : Intrinsic<[llvm_i32_ty], [], [IntrNoMem, IntrHasSideEffects]>;

  // i32 @llvm.v850.read.fpepc() - Read FPEPC (regID 7)
  def int_v850_read_fpepc
      : Intrinsic<[llvm_i32_ty], [], [IntrNoMem, IntrHasSideEffects]>;

  // i32 @llvm.v850.read.fpst() - Read FPST (regID 8)
  def int_v850_read_fpst
      : Intrinsic<[llvm_i32_ty], [], [IntrNoMem, IntrHasSideEffects]>;

  // i32 @llvm.v850.read.fpcc() - Read FPCC (regID 9)
  def int_v850_read_fpcc
      : Intrinsic<[llvm_i32_ty], [], [IntrNoMem, IntrHasSideEffects]>;

  // i32 @llvm.v850.read.fpcfg() - Read FPCFG (regID 10)
  def int_v850_read_fpcfg
      : Intrinsic<[llvm_i32_ty], [], [IntrNoMem, IntrHasSideEffects]>;

  // i32 @llvm.v850.read.fpec() - Read FPEC (regID 11)
  def int_v850_read_fpec
      : Intrinsic<[llvm_i32_ty], [], [IntrNoMem, IntrHasSideEffects]>;

  // Write FPU status registers
  // void @llvm.v850.write.fpsr(i32 %value) - Write FPSR (regID 6)
  def int_v850_write_fpsr
      : Intrinsic<[], [llvm_i32_ty], [IntrNoMem, IntrHasSideEffects]>;

  // void @llvm.v850.write.fpepc(i32 %value) - Write FPEPC (regID 7)
  def int_v850_write_fpepc
      : Intrinsic<[], [llvm_i32_ty], [IntrNoMem, IntrHasSideEffects]>;

  // void @llvm.v850.write.fpst(i32 %value) - Write FPST (regID 8)
  def int_v850_write_fpst
      : Intrinsic<[], [llvm_i32_ty], [IntrNoMem, IntrHasSideEffects]>;

  // void @llvm.v850.write.fpcc(i32 %value) - Write FPCC (regID 9)
  def int_v850_write_fpcc
      : Intrinsic<[], [llvm_i32_ty], [IntrNoMem, IntrHasSideEffects]>;

  // void @llvm.v850.write.fpcfg(i32 %value) - Write FPCFG (regID 10)
  def int_v850_write_fpcfg
      : Intrinsic<[], [llvm_i32_ty], [IntrNoMem, IntrHasSideEffects]>;

  // void @llvm.v850.write.fpec(i32 %value) - Write FPEC (regID 11)
  def int_v850_write_fpec
      : Intrinsic<[], [llvm_i32_ty], [IntrNoMem, IntrHasSideEffects]>;

  //===----------------------------------------------------------------------===//
  // Memory Barrier Operations
  //
  // V850 provides three synchronization instructions:
  // - SYNCP: Pipeline synchronization (full barrier)
  // - SYNCM: Memory synchronization
  // - SYNCE: Exception synchronization
  //===----------------------------------------------------------------------===//

  // SYNCP - Synchronize pipeline (full memory barrier)
  // void @llvm.v850.syncp()
  // Use for: __sync_synchronize(), __atomic_thread_fence(__ATOMIC_SEQ_CST)
  def int_v850_syncp : Intrinsic<[], [], [IntrNoMem, IntrHasSideEffects]>;

  // SYNCM - Synchronize memory
  // void @llvm.v850.syncm()
  // Use for: lighter-weight memory barriers (acquire/release semantics)
  def int_v850_syncm : Intrinsic<[], [], [IntrNoMem, IntrHasSideEffects]>;

  // SYNCE - Synchronize exceptions
  // void @llvm.v850.synce()
  // Use for: exception synchronization before exception-related operations
  def int_v850_synce : Intrinsic<[], [], [IntrNoMem, IntrHasSideEffects]>;

  //===----------------------------------------------------------------------===//
  // Interrupt Control Operations
  //
  // V850 provides instructions to enable/disable interrupts:
  // - DI: Disable interrupts (sets ID bit in PSW)
  // - EI: Enable interrupts (clears ID bit in PSW)
  //===----------------------------------------------------------------------===//

  // DI - Disable interrupts
  // void @llvm.v850.di()
  def int_v850_di : Intrinsic<[], [], [IntrNoMem, IntrHasSideEffects]>;

  // EI - Enable interrupts
  // void @llvm.v850.ei()
  def int_v850_ei : Intrinsic<[], [], [IntrNoMem, IntrHasSideEffects]>;

} // TargetPrefix = "v850"
