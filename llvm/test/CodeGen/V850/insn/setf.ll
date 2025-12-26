; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test SETF instruction - set flag to register

; CHECK-LABEL: test_setf_lt:
; CHECK: cmp
; CHECK: setf {{[a-z]+}}, r{{[0-9]+}}
define i32 @test_setf_lt(i32 %a, i32 %b) {
  %cmp = icmp slt i32 %a, %b
  %result = zext i1 %cmp to i32
  ret i32 %result
}

; CHECK-LABEL: test_setf_eq:
; CHECK: cmp
; CHECK: setf {{[a-z]+}}, r{{[0-9]+}}
define i32 @test_setf_eq(i32 %a, i32 %b) {
  %cmp = icmp eq i32 %a, %b
  %result = zext i1 %cmp to i32
  ret i32 %result
}

; CHECK-LABEL: test_setf_ult:
; CHECK: cmp
; CHECK: setf {{[a-z]+}}, r{{[0-9]+}}
define i32 @test_setf_ult(i32 %a, i32 %b) {
  %cmp = icmp ult i32 %a, %b
  %result = zext i1 %cmp to i32
  ret i32 %result
}
