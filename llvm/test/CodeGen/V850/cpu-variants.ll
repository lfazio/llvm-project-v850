; RUN: llc -mtriple=v850 -mcpu=g3m < %s | FileCheck %s --check-prefix=G3M
; RUN: llc -mtriple=v850 -mcpu=g3mh < %s | FileCheck %s --check-prefix=G3MH

; Test that g3m and g3mh CPU variants are recognized and generate valid code.

define i32 @test_add(i32 %a, i32 %b) {
; G3M-LABEL: test_add:
; G3M:       add r7, r6
; G3M:       mov r6, r10
; G3M:       jmp [r31]

; G3MH-LABEL: test_add:
; G3MH:      add r7, r6
; G3MH:      mov r6, r10
; G3MH:      jmp [r31]
  %result = add i32 %a, %b
  ret i32 %result
}

; Test 64-bit add uses ADF (available on G3M as it includes V850E2M)
define i64 @test_add64(i64 %a, i64 %b) {
; G3M-LABEL: test_add64:
; G3M:       add r8, r6
; G3M:       adf c, r7, r9, r11
; G3M:       mov r6, r10

; G3MH-LABEL: test_add64:
; G3MH:      add r8, r6
; G3MH:      adf c, r7, r9, r11
; G3MH:      mov r6, r10
  %result = add i64 %a, %b
  ret i64 %result
}

; Test FPU is available (G3M includes V850E2M which has FPU)
define float @test_fadd(float %a, float %b) {
; G3M-LABEL: test_fadd:
; G3M:       addf.s

; G3MH-LABEL: test_fadd:
; G3MH:      addf.s
  %result = fadd float %a, %b
  ret float %result
}
