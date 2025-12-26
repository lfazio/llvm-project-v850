; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test ADDI instruction (Format II) - add with 5-bit signed immediate

; CHECK-LABEL: test_addi_small:
; CHECK: add {{-?[0-9]+}}, r{{[0-9]+}}
define i32 @test_addi_small(i32 %a) {
  %result = add i32 %a, 5
  ret i32 %result
}

; CHECK-LABEL: test_addi_neg_small:
; CHECK: add {{-?[0-9]+}}, r{{[0-9]+}}
define i32 @test_addi_neg_small(i32 %a) {
  %result = add i32 %a, -10
  ret i32 %result
}

; Test that values outside 5-bit range use ADDI (16-bit)
; CHECK-LABEL: test_addi_large:
; CHECK: addi {{-?[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_addi_large(i32 %a) {
  %result = add i32 %a, 100
  ret i32 %result
}

