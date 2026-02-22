; RUN: llc -mtriple=v850-unknown-elf -mcpu=g3m -O2 < %s | FileCheck %s

; Test PUSHSP/POPSP for callee-saved register save/restore on RH850G3M.
;
; PUSHSP/POPSP are used when:
;   1. Target is RH850G3M or later
;   2. PREPARE/DISPOSE cannot be used (e.g., frame pointer required, or
;      registers outside r20-r31 range)
;
; PUSHSP rh, rt: pushes registers r[rh] through r[rt] to stack
; POPSP rh, rt: pops registers r[rh] through r[rt] from stack

; Test 1: PUSHSP/POPSP with frame pointer (disables PREPARE/DISPOSE)
; The frame pointer (r29) conflicts with DISPOSE's SP handling,
; so PUSHSP/POPSP is used instead.
; With no local stack frame (StackSize=0), FP is saved/restored via PUSHSP
; but not set up as an active frame pointer (no addi to initialize r29).
define void @pushsp_with_fp(ptr %p) "frame-pointer"="all" {
; CHECK-LABEL: pushsp_with_fp:
; CHECK:       pushsp r29, r29
; CHECK:       pushsp r31, r31
; CHECK-NOT:   addi {{.*}}, r3, r29
; CHECK:       jarl external
; CHECK:       popsp r31, r31
; CHECK:       popsp r29, r29
; CHECK:       jmp [r31]
entry:
  %v = load volatile i32, ptr %p
  call void @external(i32 %v)
  ret void
}

; Test 2: PUSHSP/POPSP with interrupt handler.
; Interrupt handlers save caller-saved registers (r1, r6-r19) which are
; outside the r20-r31 range required by PREPARE/DISPOSE.
define void @pushsp_interrupt() "interrupt" {
; CHECK-LABEL: pushsp_interrupt:
; CHECK:       pushsp r1, r1
; CHECK:       pushsp r3, r3
; CHECK:       pushsp r6, r19
; CHECK:       pushsp r31, r31
; Epilogue: local frame deallocation, then POPSP in reverse order
; CHECK:       popsp r31, r31
; CHECK:       popsp r6, r19
; CHECK:       popsp r3, r3
; CHECK:       popsp r1, r1
entry:
  call void @external(i32 0)
  ret void
}

; Test 3: PUSHSP/POPSP with many callee-saved registers and FP.
; When FP is used, PREPARE can't be used, so PUSHSP handles r20-r31.
; All 10 loaded values fit in CSRs (r20-r28, r30), so StackSize=0
; and FP is pushed/popped but not set up as an active frame pointer.
define i32 @pushsp_many_regs(ptr %p) "frame-pointer"="all" {
; CHECK-LABEL: pushsp_many_regs:
; CHECK:       pushsp r20, r31
; CHECK-NOT:   addi {{.*}}, r3, r29
; CHECK:       jarl external
; CHECK:       popsp r20, r31
; CHECK:       jmp [r31]
entry:
  %v0 = load volatile i32, ptr %p
  %p1 = getelementptr i32, ptr %p, i32 1
  %v1 = load volatile i32, ptr %p1
  %p2 = getelementptr i32, ptr %p, i32 2
  %v2 = load volatile i32, ptr %p2
  %p3 = getelementptr i32, ptr %p, i32 3
  %v3 = load volatile i32, ptr %p3
  %p4 = getelementptr i32, ptr %p, i32 4
  %v4 = load volatile i32, ptr %p4
  %p5 = getelementptr i32, ptr %p, i32 5
  %v5 = load volatile i32, ptr %p5
  %p6 = getelementptr i32, ptr %p, i32 6
  %v6 = load volatile i32, ptr %p6
  %p7 = getelementptr i32, ptr %p, i32 7
  %v7 = load volatile i32, ptr %p7
  %p8 = getelementptr i32, ptr %p, i32 8
  %v8 = load volatile i32, ptr %p8
  %p9 = getelementptr i32, ptr %p, i32 9
  %v9 = load volatile i32, ptr %p9

  ; Force use of many callee-saved registers across a call
  call void @external(i32 %v0)

  %s1 = add i32 %v0, %v1
  %s2 = add i32 %s1, %v2
  %s3 = add i32 %s2, %v3
  %s4 = add i32 %s3, %v4
  %s5 = add i32 %s4, %v5
  %s6 = add i32 %s5, %v6
  %s7 = add i32 %s6, %v7
  %s8 = add i32 %s7, %v8
  %s9 = add i32 %s8, %v9
  ret i32 %s9
}

; Test 4: Without FP, PREPARE/DISPOSE is preferred over PUSHSP/POPSP
; for registers in r20-r31.
define void @prepare_preferred(ptr %p) {
; CHECK-LABEL: prepare_preferred:
; CHECK:       prepare
; CHECK-NOT:   pushsp
; CHECK:       dispose
; CHECK-NOT:   popsp
entry:
  %v = load volatile i32, ptr %p
  call void @external(i32 %v)
  ret void
}

declare void @external(i32)
