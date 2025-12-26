; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test NOT instruction

; CHECK-LABEL: test_not:
; CHECK: not r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_not(i32 %a) {
  %result = xor i32 %a, -1
  ret i32 %result
}
