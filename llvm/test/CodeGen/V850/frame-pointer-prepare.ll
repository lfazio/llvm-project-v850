; RUN: llc -mtriple=v850 -mcpu=v850e2m -frame-pointer=all < %s | FileCheck %s
; RUN: llc -mtriple=v850 -mcpu=v850e2m -frame-pointer=none < %s | FileCheck %s --check-prefix=CHECK-NO-FP

; Test that PREPARE/DISPOSE is used even when frame pointer is enabled.
; Previously, canUsePrepareDispose() returned false when FP was used,
; forcing fallback to individual ST.W/LD.W instructions.

declare void @external()
declare i32 @external_func(i32)

;; Test 1: Basic function with FP and call - should use PREPARE
;
; CHECK-LABEL: basic_fp_call:
; CHECK:       prepare
; CHECK:       .cfi_def_cfa_offset 12
; CHECK:       .cfi_offset r31, -4
; CHECK:       .cfi_offset r29, -8
; CHECK:       add -4, r3
; CHECK:       .cfi_def_cfa_offset 16
; CHECK:       addi 8, r3, r29
; CHECK:       .cfi_def_cfa r29, 8
; Epilogue: restore SP from FP, then DISPOSE
; CHECK:       addi -4, r29, r3
; CHECK:       .cfi_def_cfa r3, 12
; CHECK:       dispose
;
; Without FP, uses PREPARE but no r29 in CSR list
; CHECK-NO-FP-LABEL: basic_fp_call:
; CHECK-NO-FP:       prepare
; CHECK-NO-FP:       dispose
define i32 @basic_fp_call(i32 %a) {
entry:
  %local = alloca i32
  store i32 %a, ptr %local
  call void @external()
  %v = load i32, ptr %local
  ret i32 %v
}

;; Test 2: Function with many callee-saved registers + FP
;
; CHECK-LABEL: multi_csr_fp:
; CHECK:       prepare
; CHECK:       .cfi_def_cfa_offset
; CHECK:       addi {{[0-9]+}}, r3, r29
; CHECK:       .cfi_def_cfa r29,
; Epilogue: SP restore then DISPOSE
; CHECK:       addi {{-[0-9]+}}, r29, r3
; CHECK:       dispose
define i32 @multi_csr_fp(i32 %a) {
entry:
  %local = alloca i32
  store i32 %a, ptr %local
  %c1 = call i32 @external_func(i32 %a)
  %c2 = call i32 @external_func(i32 %c1)
  %c3 = call i32 @external_func(i32 %c2)
  %v = load i32, ptr %local
  %sum = add i32 %v, %c3
  ret i32 %sum
}

;; Test 3: Variable-sized alloca (forces FP) - should use PREPARE
; StackSize == 0 case: PREPARE + FP setup, no local frame allocation
;
; CHECK-LABEL: vla_fp:
; CHECK:       prepare
; CHECK:       .cfi_def_cfa_offset 12
; CHECK:       .cfi_offset r31, -4
; CHECK:       .cfi_offset r29, -8
; CHECK:       addi 4, r3, r29
; CHECK:       .cfi_def_cfa r29, 8
; Epilogue: restore SP from FP
; CHECK:       addi -4, r29, r3
; CHECK:       .cfi_def_cfa r3, 12
; CHECK:       dispose
define i32 @vla_fp(i32 %n) {
entry:
  %vla = alloca i32, i32 %n
  store i32 42, ptr %vla
  call void @external()
  %v = load i32, ptr %vla
  ret i32 %v
}
