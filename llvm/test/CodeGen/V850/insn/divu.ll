; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test unsigned division - generates library call since UDIV is Expand

; CHECK-LABEL: test_udiv:
; CHECK: jarl __udivsi3
define i32 @test_udiv(i32 %a, i32 %b) {
  %result = udiv i32 %a, %b
  ret i32 %result
}

