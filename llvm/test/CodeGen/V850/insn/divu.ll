; RUN: llc -march=v850 -mcpu=v850e1 -O0 < %s | FileCheck %s

; Test DIVU instruction code generation
; DIVU is a V850E1+ instruction for unsigned 32-bit divide

; CHECK-LABEL: test_udiv:
; CHECK: divu r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_udiv(i32 %a, i32 %b) {
  %result = udiv i32 %a, %b
  ret i32 %result
}

