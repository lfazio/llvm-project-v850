; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test CMP instruction via conditional branches
; Use -O0 to prevent compare from being optimized away

; CHECK-LABEL: test_cmp_eq:
; CHECK: cmp r{{[0-9]+}}, r{{[0-9]+}}
; CHECK: b{{nz|z}}
define i32 @test_cmp_eq(i32 %a, i32 %b) {
  %cmp = icmp eq i32 %a, %b
  br i1 %cmp, label %then, label %else
then:
  ret i32 1
else:
  ret i32 0
}

; CHECK-LABEL: test_cmp_ne:
; CHECK: cmp r{{[0-9]+}}, r{{[0-9]+}}
; CHECK: b{{z|nz}}
define i32 @test_cmp_ne(i32 %a, i32 %b) {
  %cmp = icmp ne i32 %a, %b
  br i1 %cmp, label %then, label %else
then:
  ret i32 1
else:
  ret i32 0
}

; CHECK-LABEL: test_cmp_slt:
; CHECK: cmp r{{[0-9]+}}, r{{[0-9]+}}
; CHECK: b{{ge|lt}}
define i32 @test_cmp_slt(i32 %a, i32 %b) {
  %cmp = icmp slt i32 %a, %b
  br i1 %cmp, label %then, label %else
then:
  ret i32 1
else:
  ret i32 0
}

; CHECK-LABEL: test_cmpi:
; CHECK: cmp {{-?[0-9]+}}, r{{[0-9]+}}
define i32 @test_cmpi(i32 %a) {
  %cmp = icmp eq i32 %a, 5
  br i1 %cmp, label %then, label %else
then:
  ret i32 1
else:
  ret i32 0
}
