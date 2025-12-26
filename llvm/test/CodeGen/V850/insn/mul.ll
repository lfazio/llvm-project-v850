; RUN: llc -march=v850 -mcpu=v850e1 -O0 < %s | FileCheck %s

; Test MUL instruction code generation
; MUL is a V850E1+ instruction for 32-bit multiply

; CHECK-LABEL: test_mul:
; CHECK: mul r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_mul(i32 %a, i32 %b) {
  %result = mul i32 %a, %b
  ret i32 %result
}

