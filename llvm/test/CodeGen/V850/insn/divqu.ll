; RUN: llc -march=v850 -mcpu=v850e2m -O0 < %s | FileCheck %s

; Test DIVQU instruction code generation
; DIVQU is a V850E2M high-speed unsigned 32-bit divide with variable-step execution

; CHECK-LABEL: test_udiv:
; CHECK: divqu r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_udiv(i32 %a, i32 %b) {
  %result = udiv i32 %a, %b
  ret i32 %result
}

; CHECK-LABEL: test_urem:
; CHECK: divqu r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_urem(i32 %a, i32 %b) {
  %result = urem i32 %a, %b
  ret i32 %result
}

