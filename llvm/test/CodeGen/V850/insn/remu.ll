; RUN: llc -march=v850 -mcpu=v850e1 -O0 < %s | FileCheck %s

; Test DIVU instruction code generation for unsigned remainder
; DIVU produces both quotient (reg2) and remainder (reg3)

; CHECK-LABEL: test_urem:
; CHECK: divu r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_urem(i32 %a, i32 %b) {
  %result = urem i32 %a, %b
  ret i32 %result
}

