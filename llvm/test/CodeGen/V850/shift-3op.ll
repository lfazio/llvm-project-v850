; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m < %s | FileCheck %s --check-prefix=V850E2M
; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850    < %s | FileCheck %s --check-prefix=V850BASE

; Test that V850E2+ uses 3-operand shift instructions (SHR_3, SAR_3, SHL_3)
; when the result register differs from the source, avoiding an extra MOV.
; Base V850 must use the 2-operand (destructive) forms.

; V850E2M-LABEL: test_lshr:
; V850E2M:       shr r7, r6, r10
; V850E2M:       jmp [r31]
; V850BASE-LABEL: test_lshr:
; V850BASE:       shr r7, r6
; V850BASE:       mov r6, r10
; V850BASE:       jmp [r31]
define i32 @test_lshr(i32 %a, i32 %b) {
  %r = lshr i32 %a, %b
  ret i32 %r
}

; V850E2M-LABEL: test_ashr:
; V850E2M:       sar r7, r6, r10
; V850E2M:       jmp [r31]
; V850BASE-LABEL: test_ashr:
; V850BASE:       sar r7, r6
; V850BASE:       mov r6, r10
; V850BASE:       jmp [r31]
define i32 @test_ashr(i32 %a, i32 %b) {
  %r = ashr i32 %a, %b
  ret i32 %r
}

; V850E2M-LABEL: test_shl:
; V850E2M:       shl r7, r6, r10
; V850E2M:       jmp [r31]
; V850BASE-LABEL: test_shl:
; V850BASE:       shl r7, r6
; V850BASE:       mov r6, r10
; V850BASE:       jmp [r31]
define i32 @test_shl(i32 %a, i32 %b) {
  %r = shl i32 %a, %b
  ret i32 %r
}
