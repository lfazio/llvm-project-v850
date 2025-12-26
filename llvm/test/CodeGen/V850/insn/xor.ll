; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test XOR instruction

; CHECK-LABEL: test_xor:
; CHECK: xor r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_xor(i32 %a, i32 %b) {
  %result = xor i32 %a, %b
  ret i32 %result
}

; CHECK-LABEL: test_xori:
; CHECK: xori {{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_xori(i32 %a) {
  %result = xor i32 %a, 4095
  ret i32 %result
}
