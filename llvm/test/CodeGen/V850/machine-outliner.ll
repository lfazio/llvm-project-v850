; RUN: llc -mtriple=v850 -enable-machine-outliner < %s | FileCheck %s

; Test that the machine outliner infrastructure is working for V850.
; This is a basic test to verify the outliner methods are implemented.

;============================================================================
; Test basic code generation with outliner enabled
; The outliner may or may not extract these sequences depending on
; cost/benefit analysis, but the pass should run without crashing.
;============================================================================

; CHECK-LABEL: test_alu1:
; CHECK: add
; CHECK: jmp [r31]
define i32 @test_alu1(i32 %a, i32 %b) {
entry:
  %t1 = add i32 %a, %b
  %t2 = add i32 %t1, 100
  %t3 = add i32 %t2, 200
  ret i32 %t3
}

; CHECK-LABEL: test_alu2:
; CHECK: add
; CHECK: jmp [r31]
define i32 @test_alu2(i32 %a, i32 %b) {
entry:
  %t1 = add i32 %a, %b
  %t2 = add i32 %t1, 100
  %t3 = add i32 %t2, 200
  ret i32 %t3
}

; CHECK-LABEL: test_alu3:
; CHECK: add
; CHECK: jmp [r31]
define i32 @test_alu3(i32 %a, i32 %b) {
entry:
  %t1 = add i32 %a, %b
  %t2 = add i32 %t1, 100
  %t3 = add i32 %t2, 200
  ret i32 %t3
}

;============================================================================
; Test that calls are not outlined (they use LP register)
;============================================================================

declare i32 @external_func(i32)

; CHECK-LABEL: test_no_outline_call:
; CHECK: jarl
define i32 @test_no_outline_call(i32 %a) {
entry:
  %call = call i32 @external_func(i32 %a)
  ret i32 %call
}

;============================================================================
; Test that branches work correctly
;============================================================================

; CHECK-LABEL: test_branch:
; CHECK: ble
; CHECK: jmp [r31]
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
