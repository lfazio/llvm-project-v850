; RUN: llc -mtriple=v850 -mcpu=g3m < %s | FileCheck %s --check-prefix=G3M
; RUN: llc -mtriple=v850 -mcpu=g3mh < %s | FileCheck %s --check-prefix=G3M
; RUN: llc -mtriple=v850 -mcpu=v850e2m < %s | FileCheck %s --check-prefix=V850E2M

; Test that G3M uses native ROTL instruction while V850E2M expands it.

define i32 @test_rotl_reg(i32 %a, i32 %b) {
; G3M-LABEL: test_rotl_reg:
; G3M:       rotl r7, r6, r10
; G3M-NEXT:  jmp [r31]
;
; V850E2M-LABEL: test_rotl_reg:
; V850E2M:       shl
; V850E2M:       shr
  %result = call i32 @llvm.fshl.i32(i32 %a, i32 %a, i32 %b)
  ret i32 %result
}

define i32 @test_rotl_imm5(i32 %a) {
; G3M-LABEL: test_rotl_imm5:
; G3M:       rotl 5, r6, r10
; G3M-NEXT:  jmp [r31]
;
; V850E2M-LABEL: test_rotl_imm5:
; V850E2M:       shl 5
; V850E2M:       shr 27
  %result = call i32 @llvm.fshl.i32(i32 %a, i32 %a, i32 5)
  ret i32 %result
}

define i32 @test_rotl_imm16(i32 %a) {
; G3M-LABEL: test_rotl_imm16:
; G3M:       rotl 16, r6, r10
; G3M-NEXT:  jmp [r31]
;
; V850E2M-LABEL: test_rotl_imm16:
; V850E2M:       hsw r6, r10
  ; Note: V850E2M uses HSW for rotate by 16
  %result = call i32 @llvm.fshl.i32(i32 %a, i32 %a, i32 16)
  ret i32 %result
}

define i32 @test_rotr_reg(i32 %a, i32 %b) {
; G3M-LABEL: test_rotr_reg:
; G3M:       subr r0, r7
; G3M:       rotl r7, r6, r10
; G3M-NEXT:  jmp [r31]
;
; V850E2M-LABEL: test_rotr_reg:
; V850E2M-NOT:   rotl
  ; ROTR is expanded to ROTL with negated shift amount on G3M
  %result = call i32 @llvm.fshr.i32(i32 %a, i32 %a, i32 %b)
  ret i32 %result
}

declare i32 @llvm.fshl.i32(i32, i32, i32)
declare i32 @llvm.fshr.i32(i32, i32, i32)
