; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test AND instruction

; CHECK-LABEL: test_and:
; CHECK: and r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_and(i32 %a, i32 %b) {
  %result = and i32 %a, %b
  ret i32 %result
}

; CHECK-LABEL: test_andi:
; CHECK: andi {{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_andi(i32 %a) {
  %result = and i32 %a, 4095
  ret i32 %result
}
