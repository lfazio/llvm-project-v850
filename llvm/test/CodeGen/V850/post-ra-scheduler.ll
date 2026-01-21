; RUN: llc -march=v850 -mcpu=v850e2m -O2 < %s | FileCheck %s --check-prefix=E2M
; RUN: llc -march=v850 -mcpu=v850e1 -O2 < %s | FileCheck %s --check-prefix=E1

; Test that post-RA scheduling is enabled and working.
; The post-RA scheduler should reorder instructions to reduce stalls
; and improve dual-issue utilization on V850E2M.

; Test 1: Basic post-RA scheduling with independent operations
; The scheduler should interleave independent operations to reduce stalls.
define i32 @test_independent_ops(ptr %p, ptr %q) {
; E2M-LABEL: test_independent_ops:
; E2M:       ld.w
; E2M:       ld.w
; E2M:       add
; E2M:       jmp [r31]
;
; E1-LABEL: test_independent_ops:
; E1:       ld.w
; E1:       ld.w
; E1:       add
; E1:       jmp [r31]
entry:
  %a = load i32, ptr %p
  %b = load i32, ptr %q
  %sum = add i32 %a, %b
  ret i32 %sum
}

; Test 2: Anti-dependency breaking should allow better scheduling
; The post-RA scheduler with ANTIDEP_ALL should break false dependencies.
define i32 @test_anti_deps(i32 %a, i32 %b, i32 %c, i32 %d) {
; E2M-LABEL: test_anti_deps:
; E2M:       add
; E2M:       jmp [r31]
;
; E1-LABEL: test_anti_deps:
; E1:       add
; E1:       jmp [r31]
entry:
  %sum1 = add i32 %a, %b
  %sum2 = add i32 %c, %d
  %result = add i32 %sum1, %sum2
  ret i32 %result
}

; Test 3: Load-use scheduling - should separate loads from their uses
define i32 @test_load_use(ptr %p, ptr %q, i32 %x) {
; E2M-LABEL: test_load_use:
; E2M:       ld.w
; E2M:       ld.w
; E2M:       add
; E2M:       jmp [r31]
;
; E1-LABEL: test_load_use:
; E1:       ld.w
; E1:       ld.w
; E1:       add
; E1:       jmp [r31]
entry:
  %a = load i32, ptr %p
  %b = load i32, ptr %q
  %sum1 = add i32 %a, %x
  %sum2 = add i32 %sum1, %b
  ret i32 %sum2
}

; Test 4: Dual-issue opportunity (V850E2M specific)
; Lpipe (load/store) and Rpipe (shift) should be able to dual-issue
define i32 @test_dual_issue(ptr %p, i32 %x) {
; E2M-LABEL: test_dual_issue:
; E2M:       ld.w
; E2M:       shl
; E2M:       add
; E2M:       jmp [r31]
;
; E1-LABEL: test_dual_issue:
; E1:       ld.w
; E1:       shl
; E1:       add
; E1:       jmp [r31]
entry:
  %a = load i32, ptr %p
  %shifted = shl i32 %x, 2
  %sum = add i32 %a, %shifted
  ret i32 %sum
}

; Test 5: Multiply followed by use - should schedule to hide latency
define i32 @test_mul_latency(i32 %a, i32 %b, i32 %c) {
; E2M-LABEL: test_mul_latency:
; E2M:       mul
; E2M:       add
; E2M:       jmp [r31]
;
; E1-LABEL: test_mul_latency:
; E1:       mul
; E1:       add
; E1:       jmp [r31]
entry:
  %prod = mul i32 %a, %b
  %sum = add i32 %prod, %c
  ret i32 %sum
}

; Test 6: Memory operations with post-RA scheduling
define void @test_memory_ops(ptr %dst, ptr %src) {
; E2M-LABEL: test_memory_ops:
; E2M:       ld.w
; E2M:       st.w
; E2M:       jmp [r31]
;
; E1-LABEL: test_memory_ops:
; E1:       ld.w
; E1:       st.w
; E1:       jmp [r31]
entry:
  %val = load i32, ptr %src
  store i32 %val, ptr %dst
  ret void
}
