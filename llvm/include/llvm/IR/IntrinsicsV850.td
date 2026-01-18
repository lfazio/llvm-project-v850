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
  // Saturating Arithmetic Operations
  //
  // V850 provides signed saturating arithmetic that saturates to INT_MIN/INT_MAX.
  // Note: SATADD and SATSUB use the standard LLVM saddsat/ssubsat ISD nodes.
  // SATSUBR (reverse subtraction) requires a dedicated intrinsic.
  //===----------------------------------------------------------------------===//

  // SATSUBR - Saturating subtract reverse
  // i32 @llvm.v850.satsubr(i32 %a, i32 %b)
  // Returns: saturate(a - b), where saturation is to INT_MIN/INT_MAX
  // Note: This computes (a - b) with saturation, while ssubsat computes (b - a).
  // The "reverse" refers to operand order relative to the 2-operand instruction
  // encoding where reg2 is both source and destination.
  def int_v850_satsubr : Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty],
                                   [IntrNoMem, IntrSpeculatable, IntrWillReturn]>;

  //===----------------------------------------------------------------------===//
  // Bit Search Operations (V850E2+)
  //
  // These instructions search for the first 0 or 1 bit from left or right.
  // They return the bit position (0-31), or 32 if no bit is found.
  //===----------------------------------------------------------------------===//

  // SCH1L - Search for leftmost 1 (like 31 - CLZ, but returns 32 if input is 0)
  // i32 @llvm.v850.sch1l(i32 %x)
  // Returns: Position of leftmost 1 bit (31 = MSB, 0 = LSB), or 32 if x == 0
  def int_v850_sch1l : Intrinsic<[llvm_i32_ty], [llvm_i32_ty],
                                 [IntrNoMem, IntrSpeculatable, IntrWillReturn]>;

  // SCH1R - Search for rightmost 1 (like CTZ, but returns 32 if input is 0)
  // i32 @llvm.v850.sch1r(i32 %x)
  // Returns: Position of rightmost 1 bit (0 = LSB, 31 = MSB), or 32 if x == 0
  def int_v850_sch1r : Intrinsic<[llvm_i32_ty], [llvm_i32_ty],
                                 [IntrNoMem, IntrSpeculatable, IntrWillReturn]>;

  // SCH0L - Search for leftmost 0 (like 31 - CLO, but returns 32 if input is -1)
  // i32 @llvm.v850.sch0l(i32 %x)
  // Returns: Position of leftmost 0 bit, or 32 if x == 0xFFFFFFFF
  def int_v850_sch0l : Intrinsic<[llvm_i32_ty], [llvm_i32_ty],
                                 [IntrNoMem, IntrSpeculatable, IntrWillReturn]>;

  // SCH0R - Search for rightmost 0 (like CTO, but returns 32 if input is -1)
  // i32 @llvm.v850.sch0r(i32 %x)
  // Returns: Position of rightmost 0 bit, or 32 if x == 0xFFFFFFFF
  def int_v850_sch0r : Intrinsic<[llvm_i32_ty], [llvm_i32_ty],
                                 [IntrNoMem, IntrSpeculatable, IntrWillReturn]>;

  //===----------------------------------------------------------------------===//
  // Atomic Operations (V850E2M+)
  //===----------------------------------------------------------------------===//

  // CAXI - Compare and Exchange for Interlock
  // i32 @llvm.v850.caxi(ptr %addr, i32 %expected, i32 %desired)
  // Atomically: if (*addr == expected) *addr = desired; return old *addr
  def int_v850_caxi : Intrinsic<[llvm_i32_ty],
                                [llvm_ptr_ty, llvm_i32_ty, llvm_i32_ty],
                                [IntrArgMemOnly, NoCapture<ArgIndex<0>>]>;

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

  //===----------------------------------------------------------------------===//
  // System Register Access
  //
  // Generic intrinsics for accessing system registers via LDSR/STSR.
  // The regID parameter specifies which system register to access (0-31).
  //
  // Note: For FPU registers (regID 6-11), use the BSEL-based intrinsics
  // (llvm.v850.read/write.fpsr, etc.) which handle bank switching.
  //===----------------------------------------------------------------------===//

  // LDSR - Load to system register
  // void @llvm.v850.ldsr(i32 %value, i32 %regID)
  // Writes %value to system register specified by %regID
  def int_v850_ldsr : Intrinsic<[], [llvm_i32_ty, llvm_i32_ty],
                                [IntrNoMem, IntrHasSideEffects, ImmArg<ArgIndex<1>>]>;

  // STSR - Store from system register
  // i32 @llvm.v850.stsr(i32 %regID)
  // Reads the system register specified by %regID
  def int_v850_stsr : Intrinsic<[llvm_i32_ty], [llvm_i32_ty],
                                [IntrNoMem, IntrHasSideEffects, ImmArg<ArgIndex<0>>]>;

  //===----------------------------------------------------------------------===//
  // Multiply-Accumulate Operations (V850E2M+)
  //
  // MAC/MACU perform 32x32 multiply with 64-bit accumulate.
  // The 64-bit accumulator is represented as a register pair (hi:lo).
  // The instruction computes: (acc_hi:acc_lo) + (a * b)
  //===----------------------------------------------------------------------===//

  // MAC - Signed multiply-accumulate
  // (i32, i32) @llvm.v850.mac(i32 %a, i32 %b, i32 %acc_hi, i32 %acc_lo)
  // Returns: (result_hi, result_lo) = (acc_hi:acc_lo) + sext(a) * sext(b)
  def int_v850_mac : Intrinsic<[llvm_i32_ty, llvm_i32_ty],
                               [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
                               [IntrNoMem]>;

  // MACU - Unsigned multiply-accumulate
  // (i32, i32) @llvm.v850.macu(i32 %a, i32 %b, i32 %acc_hi, i32 %acc_lo)
  // Returns: (result_hi, result_lo) = (acc_hi:acc_lo) + zext(a) * zext(b)
  def int_v850_macu : Intrinsic<[llvm_i32_ty, llvm_i32_ty],
                                [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
                                [IntrNoMem]>;

  //===----------------------------------------------------------------------===//
  // Table-Driven Branch (V850E1+)
  //
  // SWITCH provides efficient table-driven branching for switch/case statements.
  // The instruction reads a halfword offset from a table and branches to it.
  //
  // Operation:
  //   adr = (PC + 2) + (index << 1)           ; Table entry address
  //   PC = (PC + 2) + sign_extend(mem[adr]) << 1  ; Target address
  //
  // The table must immediately follow the SWITCH instruction and contain
  // signed halfword offsets (divided by 2) from the table base to each target.
  //===----------------------------------------------------------------------===//

  // SWITCH - Jump with table look up
  // void @llvm.v850.switch(i32 %index)
  // Branches to the target specified by table[index], where the table
  // immediately follows this instruction in memory.
  // Note: This is an indirect branch - control does not fall through.
  def int_v850_switch : Intrinsic<[], [llvm_i32_ty],
                                  [IntrHasSideEffects]>;

} // TargetPrefix = "v850"
