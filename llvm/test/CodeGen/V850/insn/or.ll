; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test OR instruction

; CHECK-LABEL: test_or:
; CHECK: or r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_or(i32 %a, i32 %b) {
  %result = or i32 %a, %b
  ret i32 %result
}

; CHECK-LABEL: test_ori:
; CHECK: ori {{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_ori(i32 %a) {
  %result = or i32 %a, 4095
  ret i32 %result
}
