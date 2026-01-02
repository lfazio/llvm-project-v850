; RUN: llc -mtriple=v850 -mcpu=v850 -O2 < %s | FileCheck %s --check-prefix=V850
; RUN: llc -mtriple=v850 -mcpu=v850e2m -O2 < %s | FileCheck %s --check-prefix=V850E2M

; Test that the scheduling model is active and producing reasonable code.
; This test verifies that instruction scheduling works correctly for different
; V850 processor variants.

;============================================================================
; Integer ALU Scheduling
;============================================================================

; V850-LABEL: test_alu_sequence:
; V850E2M-LABEL: test_alu_sequence:
; Both should produce efficient ALU sequences
define i32 @test_alu_sequence(i32 %a, i32 %b, i32 %c) {
  %add1 = add i32 %a, %b
  %add2 = add i32 %add1, %c
  %sub = sub i32 %add2, 10
  ret i32 %sub
}

;============================================================================
; Memory Operation Scheduling
;============================================================================

; V850-LABEL: test_load_store:
; V850:       ld.w
; V850:       ld.w
; V850:       add
; V850:       st.w
; V850E2M-LABEL: test_load_store:
; V850E2M:   ld.w
; V850E2M:   ld.w
; V850E2M:   add
; V850E2M:   st.w
define void @test_load_store(ptr %p, ptr %q, ptr %r) {
  %a = load i32, ptr %p
  %b = load i32, ptr %q
  %sum = add i32 %a, %b
  store i32 %sum, ptr %r
  ret void
}

;============================================================================
; Integer Multiply/Divide Scheduling
; These have longer latencies and should be scheduled appropriately
;============================================================================

; V850-LABEL: test_mul_latency:
; V850E2M-LABEL: test_mul_latency:
; Multiply has 2-cycle latency, scheduler should account for this
define i32 @test_mul_latency(i32 %a, i32 %b, i32 %c) {
  %mul = mul i32 %a, %b
  %add = add i32 %mul, %c
  ret i32 %add
}

;============================================================================
; FPU Operation Scheduling (V850E2M only)
;============================================================================

; V850E2M-LABEL: test_fp_sequence:
; V850E2M:   addf.s
; V850E2M:   mulf.s
define float @test_fp_sequence(float %a, float %b, float %c) {
  %add = fadd float %a, %b
  %mul = fmul float %add, %c
  ret float %mul
}

; Test FP divide which has very long latency (~35 cycles)
; V850E2M-LABEL: test_fp_div:
; V850E2M:   divf.s
define float @test_fp_div(float %a, float %b) {
  %div = fdiv float %a, %b
  ret float %div
}

;============================================================================
; Shift Operations with Known Latencies
;============================================================================

; V850-LABEL: test_shift:
; V850:       shl
; V850E2M-LABEL: test_shift:
; V850E2M:   shl
define i32 @test_shift(i32 %a, i32 %b) {
  %shl = shl i32 %a, %b
  ret i32 %shl
}

;============================================================================
; Branch Scheduling
;============================================================================

; V850-LABEL: test_branch:
; V850E2M-LABEL: test_branch:
define i32 @test_branch(i32 %a, i32 %b) {
entry:
  %cmp = icmp sgt i32 %a, %b
  br i1 %cmp, label %if.then, label %if.else

if.then:
  %add = add i32 %a, 1
  ret i32 %add

if.else:
  %sub = sub i32 %b, 1
  ret i32 %sub
}
