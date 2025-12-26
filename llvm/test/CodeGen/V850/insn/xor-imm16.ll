; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test XORI instruction - XOR with 16-bit immediate

; CHECK-LABEL: test_xori:
; CHECK: xori {{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_xori(i32 %a) {
  %result = xor i32 %a, 1000
  ret i32 %result
}

; CHECK-LABEL: test_xori_large:
; CHECK: xori {{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_xori_large(i32 %a) {
  %result = xor i32 %a, 65535
  ret i32 %result
}
