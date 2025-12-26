; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test CALL/JARL instruction

declare i32 @external_func(i32)

; CHECK-LABEL: test_call:
; CHECK: jarl
define i32 @test_call(i32 %a) {
  %result = call i32 @external_func(i32 %a)
  ret i32 %result
}

; CHECK-LABEL: test_call_multiple_args:
; CHECK: jarl
define i32 @test_call_multiple_args(i32 %a, i32 %b, i32 %c) {
  %sum = add i32 %a, %b
  %result = call i32 @external_func(i32 %sum)
  ret i32 %result
}
