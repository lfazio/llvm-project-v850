; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test conditional branches

define i32 @test_branch_eq(i32 %a, i32 %b) {
entry:
; CHECK-LABEL: test_branch_eq:
; CHECK: cmp
; CHECK: b{{nz|z}}
  %cmp = icmp eq i32 %a, %b
  br i1 %cmp, label %if.then, label %if.else

if.then:
  ret i32 1

if.else:
  ret i32 0
}

define i32 @test_branch_slt(i32 %a, i32 %b) {
entry:
; CHECK-LABEL: test_branch_slt:
; CHECK: cmp
; CHECK: b{{lt|ge}}
  %cmp = icmp slt i32 %a, %b
  br i1 %cmp, label %if.then, label %if.else

if.then:
  ret i32 1

if.else:
  ret i32 0
}

define i32 @test_branch_ult(i32 %a, i32 %b) {
entry:
; CHECK-LABEL: test_branch_ult:
; CHECK: cmp
; CHECK: b{{c|nc}}
  %cmp = icmp ult i32 %a, %b
  br i1 %cmp, label %if.then, label %if.else

if.then:
  ret i32 1

if.else:
  ret i32 0
}
