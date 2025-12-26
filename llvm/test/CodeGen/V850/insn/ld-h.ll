; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test LD.H instruction - load halfword (sign-extended)

; CHECK-LABEL: test_ldh:
; CHECK: ld.h 0[r{{[0-9]+}}], r{{[0-9]+}}
define i32 @test_ldh(ptr %p) {
  %v = load i16, ptr %p
  %ext = sext i16 %v to i32
  ret i32 %ext
}

; CHECK-LABEL: test_ldh_offset:
; CHECK: ld.h {{[0-9]+}}[r{{[0-9]+}}], r{{[0-9]+}}
define i32 @test_ldh_offset(ptr %p) {
  %ptr = getelementptr i16, ptr %p, i32 5
  %v = load i16, ptr %ptr
  %ext = sext i16 %v to i32
  ret i32 %ext
}
