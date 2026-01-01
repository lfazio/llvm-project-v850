; RUN: llc -march=v850 -mcpu=v850e2m -O0 < %s | FileCheck %s

; Test DIVQ instruction code generation
; DIVQ is a V850E2M high-speed signed 32-bit divide with variable-step execution

; CHECK-LABEL: test_sdiv:
; CHECK: divq r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_sdiv(i32 %a, i32 %b) {
  %result = sdiv i32 %a, %b
  ret i32 %result
}

; CHECK-LABEL: test_srem:
; CHECK: divq r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_srem(i32 %a, i32 %b) {
  %result = srem i32 %a, %b
  ret i32 %result
}

