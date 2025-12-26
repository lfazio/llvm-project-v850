; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test unconditional branch (JR/BR instruction)

; CHECK-LABEL: test_br:
; CHECK: jr
define i32 @test_br(i32 %a) {
entry:
  br label %target
target:
  ret i32 %a
}

; Test loop with unconditional branch back
; CHECK-LABEL: test_loop:
; CHECK: jr
define i32 @test_loop(i32 %n) {
entry:
  br label %loop
loop:
  %i = phi i32 [0, %entry], [%next, %loop]
  %next = add i32 %i, 1
  %cond = icmp slt i32 %next, %n
  br i1 %cond, label %loop, label %exit
exit:
  ret i32 %next
}
