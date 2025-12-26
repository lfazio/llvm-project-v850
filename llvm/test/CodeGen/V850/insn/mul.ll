; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test multiplication - generates library call since MUL is Expand

; CHECK-LABEL: test_mul:
; CHECK: jarl __mulsi3
define i32 @test_mul(i32 %a, i32 %b) {
  %result = mul i32 %a, %b
  ret i32 %result
}

; CHECK-LABEL: test_mul_const:
; CHECK: jarl __mulsi3
define i32 @test_mul_const(i32 %a) {
  %result = mul i32 %a, 10
  ret i32 %result
}

