; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test SAR instruction - arithmetic shift right

; CHECK-LABEL: test_sar:
; CHECK: sar r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_sar(i32 %a, i32 %b) {
  %result = ashr i32 %a, %b
  ret i32 %result
}

; CHECK-LABEL: test_sari:
; CHECK: sar {{[0-9]+}}, r{{[0-9]+}}
define i32 @test_sari(i32 %a) {
  %result = ashr i32 %a, 5
  ret i32 %result
}
