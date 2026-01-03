; RUN: llc -mtriple=v850 -O2 < %s | FileCheck %s

; Test register allocation behavior
; Verifies:
; 1. r1 (assembler temp) is not used for register allocation
; 2. Caller-saved registers are preferred for short-lived values
; 3. Reserved registers (r0, sp, gp, tp) are not allocated

;============================================================================
; Test that r1 is not allocated
;============================================================================

; CHECK-LABEL: test_no_r1_alloc:
; Ensure we use caller-saved temps (r10-r19) or argument regs (r6-r9)
; but never r1 (assembler temp which is reserved)
; CHECK-NOT: , r1,
; CHECK-NOT: , r1{{$}}
; CHECK-NOT: [r1]
define i32 @test_no_r1_alloc(i32 %a, i32 %b, i32 %c, i32 %d) {
  %sum1 = add i32 %a, %b
  %sum2 = add i32 %c, %d
  %result = add i32 %sum1, %sum2
  ret i32 %result
}

;============================================================================
; Test that caller-saved registers are used first
;============================================================================

; CHECK-LABEL: test_caller_saved_first:
; The temporaries should use r10-r19 (caller-saved) before r20-r29 (callee-saved)
; CHECK: r{{[6-9]|1[0-9]}}
define i32 @test_caller_saved_first(i32 %a) {
  %t1 = add i32 %a, 1
  %t2 = add i32 %t1, 2
  %t3 = add i32 %t2, 3
  ret i32 %t3
}

;============================================================================
; Test callee-saved register usage across calls
;============================================================================

declare i32 @external_func(i32)

; CHECK-LABEL: test_callee_saved_across_call:
; Values live across calls should be in callee-saved registers (r20-r29)
; or spilled to stack
; CHECK: jarl
define i32 @test_callee_saved_across_call(i32 %a, i32 %b) {
entry:
  %call1 = call i32 @external_func(i32 %a)
  %sum = add i32 %call1, %b
  ret i32 %sum
}

;============================================================================
; Test that reserved registers are not allocated
;============================================================================

; CHECK-LABEL: test_reserved_regs:
; Should not use r0 (zero), r3 (sp), r4 (gp), r5 (tp) for temps
; CHECK-NOT: mov {{.*}}, r0
; CHECK-NOT: add {{.*}}, r3,
; CHECK-NOT: add {{.*}}, r4,
; CHECK-NOT: add {{.*}}, r5,
define i32 @test_reserved_regs(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e) {
  %t1 = add i32 %a, %b
  %t2 = add i32 %c, %d
  %t3 = add i32 %t1, %t2
  %t4 = add i32 %t3, %e
  ret i32 %t4
}

;============================================================================
; Test high register pressure (forces use of callee-saved)
;============================================================================

; CHECK-LABEL: test_high_pressure:
; With high register pressure, should spill or use callee-saved registers
define i32 @test_high_pressure(i32 %a, i32 %b, i32 %c, i32 %d) {
  %t1 = add i32 %a, 1
  %t2 = add i32 %b, 2
  %t3 = add i32 %c, 3
  %t4 = add i32 %d, 4
  %t5 = mul i32 %t1, %t2
  %t6 = mul i32 %t3, %t4
  %t7 = add i32 %t5, %t6
  %t8 = add i32 %t7, %t1
  %t9 = add i32 %t8, %t2
  %t10 = add i32 %t9, %t3
  %result = add i32 %t10, %t4
  ret i32 %result
}
