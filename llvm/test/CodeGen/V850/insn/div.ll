; RUN: llc -march=v850 -mcpu=v850e1 -O0 < %s | FileCheck %s

; Test DIV instruction code generation
; DIV is a V850E1+ instruction for signed 32-bit divide

; CHECK-LABEL: test_sdiv:
; CHECK: div r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_sdiv(i32 %a, i32 %b) {
  %result = sdiv i32 %a, %b
  ret i32 %result
}

