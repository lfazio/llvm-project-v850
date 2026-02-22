; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m < %s | FileCheck %s

; Test that epilogue CFI directives are properly emitted
; V850 follows the "prologue-only" CFI philosophy - epilogue CFI only updates
; the CFA offset after stack deallocation, not register restores.

declare void @external()

; Simple function with call - tests PREPARE/DISPOSE path
; PREPARE saves LP (r31) only. No local variables, no stack-passed args,
; so no local stack allocation is needed. The call passes no arguments.
define void @test_epilogue_cfi_prepare() {
; CHECK-LABEL: test_epilogue_cfi_prepare:
; CHECK:       .cfi_startproc
; CHECK:       prepare 2048, 0
; CHECK-NEXT:  .cfi_def_cfa_offset 4
; CHECK-NEXT:  .cfi_offset r31, -4
; No prologue stack adjustment (no local frame)
; CHECK-NOT:   add {{.*}}, r3
; CHECK:       jarl external
; No epilogue stack adjustment
; DISPOSE with return
; CHECK:       dispose 0, 2048, [r31]
; CHECK:       .cfi_endproc
  call void @external()
  ret void
}

; Function with multiple CSRs (LP + r21 + r20).
; No local stack allocation needed: values kept in CSRs across the call.
define void @test_epilogue_cfi_multi_csr(ptr %p) {
; CHECK-LABEL: test_epilogue_cfi_multi_csr:
; CHECK:       .cfi_startproc
; CHECK:       prepare 2051, 0
; CHECK-NEXT:  .cfi_def_cfa_offset 12
; CHECK-NEXT:  .cfi_offset r31, -4
; CHECK-NEXT:  .cfi_offset r21, -8
; CHECK-NEXT:  .cfi_offset r20, -12
; No prologue stack adjustment
; CHECK-NOT:   add {{.*}}, r3
; CHECK:       jarl external
; No epilogue stack adjustment
; DISPOSE with return
; CHECK:       dispose 0, 2051, [r31]
; CHECK:       .cfi_endproc
  %x = load volatile i32, ptr %p
  call void @external()
  store volatile i32 %x, ptr %p
  ret void
}

; Leaf function with no calls - should have minimal CFI
define i32 @test_leaf(i32 %a, i32 %b) {
; CHECK-LABEL: test_leaf:
; CHECK:       .cfi_startproc
; CHECK-NOT:   prepare
; CHECK-NOT:   dispose
; CHECK:       jmp [r31]
; CHECK:       .cfi_endproc
  %c = add i32 %a, %b
  ret i32 %c
}
