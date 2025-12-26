; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test signed remainder - generates library call since SREM is Expand

; CHECK-LABEL: test_srem:
; CHECK: jarl __modsi3
define i32 @test_srem(i32 %a, i32 %b) {
  %result = srem i32 %a, %b
  ret i32 %result
}

