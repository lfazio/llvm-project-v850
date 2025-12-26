; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test ANDI instruction - AND with 16-bit immediate

; CHECK-LABEL: test_andi:
; CHECK: andi {{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_andi(i32 %a) {
  %result = and i32 %a, 1000
  ret i32 %result
}

; CHECK-LABEL: test_andi_mask:
; CHECK: andi {{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_andi_mask(i32 %a) {
  %result = and i32 %a, 4095
  ret i32 %result
}
