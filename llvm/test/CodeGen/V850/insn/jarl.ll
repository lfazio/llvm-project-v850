; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test JARL instruction - jump and register link (function call)

declare void @external_func()
declare i32 @external_func_ret()

; CHECK-LABEL: test_jarl:
; CHECK: jarl external_func, r31
define void @test_jarl() {
  call void @external_func()
  ret void
}

; CHECK-LABEL: test_jarl_ret:
; CHECK: jarl external_func_ret, r31
define i32 @test_jarl_ret() {
  %result = call i32 @external_func_ret()
  ret i32 %result
}

