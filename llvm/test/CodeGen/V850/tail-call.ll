; RUN: llc -march=v850 -mcpu=v850e1 < %s | FileCheck %s

; Test tail call optimization for V850

declare i32 @bar(i32 %x)
declare i32 @baz(i32 %x, i32 %y)

; Simple tail call - should generate jr instead of jarl + return
define i32 @simple_tailcall(i32 %x) {
; CHECK-LABEL: simple_tailcall:
; CHECK-NOT: jarl
; CHECK-NOT: prepare
; CHECK: jr bar
; CHECK-NOT: jmp
  %r = tail call i32 @bar(i32 %x)
  ret i32 %r
}

; Non-tail call - should generate jarl and return
define i32 @non_tailcall(i32 %x) {
; CHECK-LABEL: non_tailcall:
; CHECK: prepare
; CHECK: jarl bar, r31
; CHECK: dispose
  %r = call i32 @bar(i32 %x)
  ret i32 %r
}

; Tail call with multiple args still in registers
define i32 @tailcall_multi_args(i32 %x, i32 %y) {
; CHECK-LABEL: tailcall_multi_args:
; CHECK-NOT: jarl
; CHECK-NOT: prepare
; CHECK: jr baz
  %r = tail call i32 @baz(i32 %x, i32 %y)
  ret i32 %r
}

; Cannot tail call if there's computation after the call
define i32 @no_tailcall_post_compute(i32 %x) {
; CHECK-LABEL: no_tailcall_post_compute:
; CHECK: jarl bar, r31
; CHECK-NOT: jr bar
  %r = call i32 @bar(i32 %x)
  %s = add i32 %r, 1
  ret i32 %s
}

; When callee needs more stack args than caller provides, cannot tail call
; This tests the case where callee requires stack arguments
declare i32 @many_args(i32, i32, i32, i32, i32, i32, i32)

define i32 @no_tailcall_callee_stack(i32 %a, i32 %b) {
; CHECK-LABEL: no_tailcall_callee_stack:
; CHECK: jarl many_args, r31
; Callee needs 7 args (3 on stack), tail call not allowed
  %r = tail call i32 @many_args(i32 %a, i32 %b, i32 1, i32 2, i32 3, i32 4, i32 5)
  ret i32 %r
}
