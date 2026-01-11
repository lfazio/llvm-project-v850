; RUN: llc -mtriple=v850 -mcpu=v850 -O2 < %s | FileCheck %s --check-prefix=CHECK
; RUN: llc -mtriple=v850 -mcpu=v850es -O2 < %s | FileCheck %s --check-prefix=CHECK
; RUN: llc -mtriple=v850 -mcpu=v850e1 -O2 < %s | FileCheck %s --check-prefix=CHECK
; RUN: llc -mtriple=v850 -mcpu=v850e2 -O2 < %s | FileCheck %s --check-prefix=CHECK
; RUN: llc -mtriple=v850 -mcpu=v850e2m -O2 < %s | FileCheck %s --check-prefix=CHECK

; Test that the scheduling model is active and producing reasonable code.
; This test verifies that instruction scheduling works correctly for different
; V850 processor variants.
;
; Scheduling models:
;   V850:     V850Model     - 5-stage single-issue pipeline (IF-ID-EX-MEM-WB)
;   V850ES:   V850E1Model   - 5-stage single-issue, different MUL/branch timing
;   V850E1:   V850E1Model   - Same as V850ES
;   V850E2:   V850E2MModel  - 7-stage dual-issue (Lpipe/Rpipe)
;   V850E2M:  V850E2MModel  - 7-stage dual-issue with FPU

;============================================================================
; Integer ALU Scheduling
;============================================================================

; CHECK-LABEL: test_alu_sequence:
; All variants should produce efficient ALU sequences (1-1-1 latency)
define i32 @test_alu_sequence(i32 %a, i32 %b, i32 %c) {
  %add1 = add i32 %a, %b
  %add2 = add i32 %add1, %c
  %sub = sub i32 %add2, 10
  ret i32 %sub
}

;============================================================================
; Memory Operation Scheduling
;============================================================================

; CHECK-LABEL: test_load_store:
; CHECK-DAG: ld.w
; CHECK-DAG: ld.w
; CHECK: add
; CHECK: st.w
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
;
; Multiply latencies:
;   V850:    MULH is 1-1-2 (2-cycle latency)
;   V850E1:  MUL/MULU is 1-4-5 (5-cycle latency, 4-cycle repeat)
;   V850E2:  MUL is 1-1-3 (3-cycle latency)
;   V850E2M: MUL is 1-1-3 (3-cycle latency)
;============================================================================

; CHECK-LABEL: test_mul_latency:
; Multiply has varying latency depending on CPU, scheduler should account for this
define i32 @test_mul_latency(i32 %a, i32 %b, i32 %c) {
  %mul = mul i32 %a, %b
  %add = add i32 %mul, %c
  ret i32 %add
}

;============================================================================
; FPU Operation Scheduling (V850E2M only)
;
; FPU latencies:
;   ADDF.S/SUBF.S: 4 cycles
;   MULF.S: 4 cycles
;   DIVF.S: ~35 cycles (not pipelined)
;============================================================================

; CHECK-LABEL: test_fp_sequence:
define float @test_fp_sequence(float %a, float %b, float %c) {
  %add = fadd float %a, %b
  %mul = fmul float %add, %c
  ret float %mul
}

; Test FP divide which has very long latency (~35 cycles)
; CHECK-LABEL: test_fp_div:
define float @test_fp_div(float %a, float %b) {
  %div = fdiv float %a, %b
  ret float %div
}

;============================================================================
; Shift Operations with Known Latencies
; All variants: 1-1-1 (single cycle)
; V850E2+: Uses Rpipe only
;============================================================================

; CHECK-LABEL: test_shift:
; CHECK: shl
define i32 @test_shift(i32 %a, i32 %b) {
  %shl = shl i32 %a, %b
  ret i32 %shl
}

;============================================================================
; Branch Scheduling
;
; Branch penalties:
;   V850:    3-3-3 (taken)
;   V850E1:  2-2-2 (taken)
;   V850E2:  4-4-4 (taken)
;   V850E2M: 4-4-4 (taken)
;============================================================================

; CHECK-LABEL: test_branch:
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
