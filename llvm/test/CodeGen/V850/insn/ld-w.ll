; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test LD.W instruction - load word

; CHECK-LABEL: test_ldw:
; CHECK: ld.w 0[r{{[0-9]+}}], r{{[0-9]+}}
define i32 @test_ldw(ptr %p) {
  %v = load i32, ptr %p
  ret i32 %v
}

; CHECK-LABEL: test_ldw_offset:
; CHECK: ld.w {{[0-9]+}}[r{{[0-9]+}}], r{{[0-9]+}}
define i32 @test_ldw_offset(ptr %p) {
  %ptr = getelementptr i32, ptr %p, i32 5
  %v = load i32, ptr %ptr
  ret i32 %v
}
