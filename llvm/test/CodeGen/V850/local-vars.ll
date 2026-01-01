; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test local variable allocation and access

define i32 @test_local_var(i32 %a) {
entry:
; CHECK-LABEL: test_local_var:
; CHECK: add -{{[0-9]+}}, r3
; CHECK: st.w
; CHECK: ld.w
  %local = alloca i32
  store i32 %a, ptr %local
  %result = load i32, ptr %local
  ret i32 %result
}

define i32 @test_multiple_locals(i32 %a, i32 %b) {
entry:
; CHECK-LABEL: test_multiple_locals:
; CHECK: add -{{[0-9]+}}, r3
; CHECK: st.w
; CHECK: st.w
; CHECK: ld.w
; CHECK: ld.w
  %x = alloca i32
  %y = alloca i32
  store i32 %a, ptr %x
  store i32 %b, ptr %y
  %vx = load i32, ptr %x
  %vy = load i32, ptr %y
  %result = add i32 %vx, %vy
  ret i32 %result
}
