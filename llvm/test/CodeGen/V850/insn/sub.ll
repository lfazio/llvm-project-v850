; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test SUB instruction

; CHECK-LABEL: test_sub:
; CHECK: sub r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_sub(i32 %a, i32 %b) {
  %result = sub i32 %a, %b
  ret i32 %result
}
