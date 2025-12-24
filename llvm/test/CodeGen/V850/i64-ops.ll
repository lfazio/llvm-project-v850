; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test 64-bit operations (split into 32-bit pairs)

define i64 @test_add64(i64 %a, i64 %b) {
entry:
; CHECK-LABEL: test_add64:
; CHECK: add
; CHECK: cmp
; CHECK: setf
; CHECK: add
; CHECK: add
  %result = add i64 %a, %b
  ret i64 %result
}

define i64 @test_sub64(i64 %a, i64 %b) {
entry:
; CHECK-LABEL: test_sub64:
; CHECK: sub
; CHECK: cmp
; CHECK: setf
; CHECK: sub
; CHECK: sub
  %result = sub i64 %a, %b
  ret i64 %result
}

define i32 @test_setcc(i32 %a, i32 %b) {
entry:
; CHECK-LABEL: test_setcc:
; CHECK: cmp
; CHECK: setf
  %cmp = icmp slt i32 %a, %b
  %result = zext i1 %cmp to i32
  ret i32 %result
}
