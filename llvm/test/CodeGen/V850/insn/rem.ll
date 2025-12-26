; RUN: llc -march=v850 -mcpu=v850e1 -O0 < %s | FileCheck %s

; Test DIV instruction code generation for signed remainder
; DIV produces both quotient (reg2) and remainder (reg3)

; CHECK-LABEL: test_srem:
; CHECK: div r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_srem(i32 %a, i32 %b) {
  %result = srem i32 %a, %b
  ret i32 %result
}

