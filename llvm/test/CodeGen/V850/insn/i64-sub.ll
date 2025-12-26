; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test 64-bit subtraction (split into 32-bit pairs with borrow)

; CHECK-LABEL: test_sub64:
; CHECK: sub
; CHECK: cmp
; CHECK: setf
; CHECK: sub
; CHECK: sub
define i64 @test_sub64(i64 %a, i64 %b) {
  %result = sub i64 %a, %b
  ret i64 %result
}
