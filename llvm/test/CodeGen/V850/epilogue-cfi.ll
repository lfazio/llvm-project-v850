; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m < %s | FileCheck %s

; Test that epilogue CFI directives are properly emitted
; V850 follows the "prologue-only" CFI philosophy - epilogue CFI only updates
; the CFA offset after stack deallocation, not register restores.

declare void @external()

; Simple function with call - tests PREPARE/DISPOSE path
define void @test_epilogue_cfi_prepare() {
; CHECK-LABEL: test_epilogue_cfi_prepare:
; CHECK:       .cfi_startproc
; CHECK:       prepare
; CHECK:       .cfi_def_cfa_offset 4
; CHECK:       .cfi_offset r31, -4
; Prologue stack adjustment
; CHECK:       add
; CHECK:       .cfi_def_cfa_offset
; Call
; CHECK:       jarl external
; Epilogue stack adjustment
; CHECK:       add
; CHECK:       .cfi_def_cfa_offset 4
; DISPOSE with return (note: no cfi_restore in epilogue per prologue-only philosophy)
; CHECK:       dispose 0, 2048, [r31]
; CHECK:       .cfi_endproc
  call void @external()
  ret void
}

; Function with multiple CSRs
define void @test_epilogue_cfi_multi_csr(ptr %p) {
; CHECK-LABEL: test_epilogue_cfi_multi_csr:
; CHECK:       .cfi_startproc
; CHECK:       prepare
; CHECK:       .cfi_def_cfa_offset 12
; CHECK:       .cfi_offset r31, -4
; CHECK:       .cfi_offset r21, -8
; CHECK:       .cfi_offset r20, -12
; Prologue
; CHECK:       add
; CHECK:       .cfi_def_cfa_offset
; CHECK:       jarl external
; Epilogue
; CHECK:       add
; CHECK:       .cfi_def_cfa_offset 12
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
