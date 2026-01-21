; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m -O2 < %s | FileCheck %s

; Test that simple select patterns are converted to CMOV instructions

; CHECK-LABEL: test_select_eq:
; CHECK: cmp
; CHECK: cmov
define i32 @test_select_eq(i32 %a, i32 %b, i32 %x, i32 %y) {
  %cmp = icmp eq i32 %a, %b
  %sel = select i1 %cmp, i32 %x, i32 %y
  ret i32 %sel
}

; CHECK-LABEL: test_select_slt:
; CHECK: cmp
; CHECK: cmov
define i32 @test_select_slt(i32 %a, i32 %b, i32 %x, i32 %y) {
  %cmp = icmp slt i32 %a, %b
  %sel = select i1 %cmp, i32 %x, i32 %y
  ret i32 %sel
}

; CHECK-LABEL: test_select_ult:
; CHECK: cmp
; CHECK: cmov
define i32 @test_select_ult(i32 %a, i32 %b, i32 %x, i32 %y) {
  %cmp = icmp ult i32 %a, %b
  %sel = select i1 %cmp, i32 %x, i32 %y
  ret i32 %sel
}

; CHECK-LABEL: test_select_sge:
; CHECK: cmp
; CHECK: cmov
define i32 @test_select_sge(i32 %a, i32 %b, i32 %x, i32 %y) {
  %cmp = icmp sge i32 %a, %b
  %sel = select i1 %cmp, i32 %x, i32 %y
  ret i32 %sel
}

; Test min/max patterns that should use CMOV
; CHECK-LABEL: test_smin:
; CHECK: cmp
; CHECK: cmov
define i32 @test_smin(i32 %a, i32 %b) {
  %cmp = icmp slt i32 %a, %b
  %sel = select i1 %cmp, i32 %a, i32 %b
  ret i32 %sel
}

; CHECK-LABEL: test_smax:
; CHECK: cmp
; CHECK: cmov
define i32 @test_smax(i32 %a, i32 %b) {
  %cmp = icmp sgt i32 %a, %b
  %sel = select i1 %cmp, i32 %a, i32 %b
  ret i32 %sel
}

; CHECK-LABEL: test_umin:
; CHECK: cmp
; CHECK: cmov
define i32 @test_umin(i32 %a, i32 %b) {
  %cmp = icmp ult i32 %a, %b
  %sel = select i1 %cmp, i32 %a, i32 %b
  ret i32 %sel
}

; CHECK-LABEL: test_umax:
; CHECK: cmp
; CHECK: cmov
define i32 @test_umax(i32 %a, i32 %b) {
  %cmp = icmp ugt i32 %a, %b
  %sel = select i1 %cmp, i32 %a, i32 %b
  ret i32 %sel
}

; Test conditional assignment (not abs - abs uses arithmetic optimization)
; CHECK-LABEL: test_conditional_assign:
; CHECK: cmp
; CHECK: cmov
define i32 @test_conditional_assign(i32 %a, i32 %b, i32 %c) {
  %cmp = icmp ne i32 %a, 0
  %sel = select i1 %cmp, i32 %b, i32 %c
  ret i32 %sel
}
