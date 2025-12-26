; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test unsigned remainder - generates library call since UREM is Expand

; CHECK-LABEL: test_urem:
; CHECK: jarl __umodsi3
define i32 @test_urem(i32 %a, i32 %b) {
  %result = urem i32 %a, %b
  ret i32 %result
}

