; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test SHR instruction - logical shift right

; CHECK-LABEL: test_shr:
; CHECK: shr r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_shr(i32 %a, i32 %b) {
  %result = lshr i32 %a, %b
  ret i32 %result
}

; CHECK-LABEL: test_shri:
; CHECK: shr {{[0-9]+}}, r{{[0-9]+}}
define i32 @test_shri(i32 %a) {
  %result = lshr i32 %a, 5
  ret i32 %result
}
