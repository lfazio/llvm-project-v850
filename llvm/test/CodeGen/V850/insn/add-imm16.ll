; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test ADDI instruction - ADD with 16-bit immediate

; CHECK-LABEL: test_addi:
; CHECK: addi {{-?[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_addi(i32 %a) {
  %result = add i32 %a, 1000
  ret i32 %result
}

; CHECK-LABEL: test_addi_neg:
; CHECK: addi {{-?[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_addi_neg(i32 %a) {
  %result = add i32 %a, -500
  ret i32 %result
}

; CHECK-LABEL: test_addi_max:
; CHECK: addi {{-?[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_addi_max(i32 %a) {
  %result = add i32 %a, 32767
  ret i32 %result
}
