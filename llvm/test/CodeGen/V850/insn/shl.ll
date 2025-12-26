; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test SHL instruction - shift left

; CHECK-LABEL: test_shl:
; CHECK: shl r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_shl(i32 %a, i32 %b) {
  %result = shl i32 %a, %b
  ret i32 %result
}

; CHECK-LABEL: test_shli:
; CHECK: shl {{[0-9]+}}, r{{[0-9]+}}
define i32 @test_shli(i32 %a) {
  %result = shl i32 %a, 5
  ret i32 %result
}
