; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test signed division - generates library call since SDIV is Expand

; CHECK-LABEL: test_sdiv:
; CHECK: jarl __divsi3
define i32 @test_sdiv(i32 %a, i32 %b) {
  %result = sdiv i32 %a, %b
  ret i32 %result
}

