; RUN: llc -mtriple=v850 -mcpu=v850e1 -enable-shrink-wrap=true < %s | FileCheck %s --check-prefix=CHECK-SHRINK
; RUN: llc -mtriple=v850 -mcpu=v850e1 -enable-shrink-wrap=false < %s | FileCheck %s --check-prefix=CHECK-NOSHRINK
; RUN: llc -mtriple=v850 -mcpu=v850e2m -enable-shrink-wrap=true < %s | FileCheck %s --check-prefix=CHECK-SHRINK

;===----------------------------------------------------------------------===;
; Test shrink wrapping optimization
;
; Shrink wrapping moves prologue/epilogue code closer to where callee-saved
; registers are actually used, reducing overhead on early-exit paths.
;===----------------------------------------------------------------------===;

;===----------------------------------------------------------------------===;
; Test 1: Early exit path should skip callee-saved register saves
;
; When shrink wrapping is enabled, the early return path should not
; execute the prologue (no PREPARE/callee saves).
;===----------------------------------------------------------------------===;

; With shrink wrapping:
; - Entry block: conditional branch, NO prepare
; - early_exit: mov 0, jmp - no prepare/dispose
; - do_work: prepare, call, dispose

; CHECK-SHRINK-LABEL: test_early_exit:
; CHECK-SHRINK:       bz .L
; CHECK-SHRINK:       prepare
; CHECK-SHRINK:       jarl
; CHECK-SHRINK:       dispose
; CHECK-SHRINK:       mov 0, r10
; CHECK-SHRINK-NEXT:  jmp [r31]

; CHECK-NOSHRINK-LABEL: test_early_exit:
; Without shrink wrapping, PREPARE comes first unconditionally
; CHECK-NOSHRINK:       prepare
; CHECK-NOSHRINK:       bz .L
define i32 @test_early_exit(i32 %a, i32 %b) {
entry:
  %cmp = icmp eq i32 %a, 0
  br i1 %cmp, label %early_exit, label %do_work

early_exit:
  ret i32 0

do_work:
  %call = call i32 @external_func(i32 %a, i32 %b)
  ret i32 %call
}

;===----------------------------------------------------------------------===;
; Test 2: Multiple early exits - all early paths skip prologue
;===----------------------------------------------------------------------===;

; With shrink wrapping:
; - Entry and check_b: conditional branches, no prepare
; - return_zero/return_one: mov, jmp - no prepare
; - do_work: prepare, call, dispose

; CHECK-SHRINK-LABEL: test_multiple_exits:
; CHECK-SHRINK:       bz .L
; CHECK-SHRINK:       bz .L
; CHECK-SHRINK:       prepare
; CHECK-SHRINK:       jarl
; Early exit paths have just mov and jmp
; CHECK-SHRINK:       mov 0, r10
; CHECK-SHRINK:       jmp [r31]
; CHECK-SHRINK:       mov 1, r10
; CHECK-SHRINK:       jmp [r31]

; CHECK-NOSHRINK-LABEL: test_multiple_exits:
; CHECK-NOSHRINK:       prepare
define i32 @test_multiple_exits(i32 %a, i32 %b, i32 %c) {
entry:
  %cmp1 = icmp eq i32 %a, 0
  br i1 %cmp1, label %return_zero, label %check_b

check_b:
  %cmp2 = icmp eq i32 %b, 0
  br i1 %cmp2, label %return_one, label %do_work

do_work:
  %call = call i32 @external_func(i32 %a, i32 %b)
  %result = add i32 %call, %c
  ret i32 %result

return_zero:
  ret i32 0

return_one:
  ret i32 1
}

;===----------------------------------------------------------------------===;
; Test 3: No shrink wrapping benefit when all paths need prologue
;
; When all paths need the callee-saved registers (make calls at entry),
; prologue is placed at entry.
;===----------------------------------------------------------------------===;

; Both configs should have prepare at entry
; CHECK-SHRINK-LABEL: test_all_paths_need_prologue:
; CHECK-SHRINK:       prepare
; CHECK-SHRINK:       jarl
; CHECK-NOSHRINK-LABEL: test_all_paths_need_prologue:
; CHECK-NOSHRINK:       prepare
define i32 @test_all_paths_need_prologue(i32 %a, i32 %b) {
entry:
  %call1 = call i32 @external_func(i32 %a, i32 %b)
  %cmp = icmp eq i32 %call1, 0
  br i1 %cmp, label %path1, label %path2

path1:
  %call2 = call i32 @external_func(i32 %call1, i32 %a)
  ret i32 %call2

path2:
  %call3 = call i32 @external_func(i32 %call1, i32 %b)
  ret i32 %call3
}

;===----------------------------------------------------------------------===;
; Test 4: Loop with early exit
;===----------------------------------------------------------------------===;

; With shrink wrapping:
; - Early exit (n <= 0) goes directly to return_zero: mov 0, jmp
; - Loop path has prepare in loop_preheader

; CHECK-SHRINK-LABEL: test_loop_early_exit:
; Check early exit path comes first (no prepare before jmp)
; CHECK-SHRINK:       mov 0, r10
; CHECK-SHRINK-NEXT:  jmp [r31]
; Loop path has prepare
; CHECK-SHRINK:       prepare
; CHECK-SHRINK:       jarl

; CHECK-NOSHRINK-LABEL: test_loop_early_exit:
; CHECK-NOSHRINK:       prepare
define i32 @test_loop_early_exit(i32 %n, ptr %arr) {
entry:
  %cmp = icmp sle i32 %n, 0
  br i1 %cmp, label %return_zero, label %loop_preheader

loop_preheader:
  br label %loop

loop:
  %i = phi i32 [ 0, %loop_preheader ], [ %i.next, %loop ]
  %sum = phi i32 [ 0, %loop_preheader ], [ %sum.next, %loop ]
  %ptr = getelementptr i32, ptr %arr, i32 %i
  %val = load i32, ptr %ptr
  %call = call i32 @external_func(i32 %val, i32 %sum)
  %sum.next = add i32 %sum, %call
  %i.next = add i32 %i, 1
  %cmp.loop = icmp slt i32 %i.next, %n
  br i1 %cmp.loop, label %loop, label %return_sum

return_zero:
  ret i32 0

return_sum:
  ret i32 %sum.next
}

;===----------------------------------------------------------------------===;
; Test 5: Function with no calls should have no prologue at all
;===----------------------------------------------------------------------===;

; CHECK-SHRINK-LABEL: test_no_calls:
; CHECK-SHRINK-NOT:   prepare
; CHECK-SHRINK:       jmp [r31]
; CHECK-NOSHRINK-LABEL: test_no_calls:
; CHECK-NOSHRINK-NOT:   prepare
define i32 @test_no_calls(i32 %a, i32 %b) {
entry:
  %cmp = icmp eq i32 %a, 0
  br i1 %cmp, label %early_exit, label %do_work

early_exit:
  ret i32 0

do_work:
  %add = add i32 %a, %b
  ret i32 %add
}

declare i32 @external_func(i32, i32)
