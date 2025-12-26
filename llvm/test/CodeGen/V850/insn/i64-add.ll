; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test 64-bit addition (split into 32-bit pairs with carry)

; CHECK-LABEL: test_add64:
; CHECK: add
; CHECK: cmp
; CHECK: setf
; CHECK: add
; CHECK: add
define i64 @test_add64(i64 %a, i64 %b) {
  %result = add i64 %a, %b
  ret i64 %result
}
