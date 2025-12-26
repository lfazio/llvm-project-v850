; RUN: llc -march=v850 -mcpu=v850e1 -O0 < %s | FileCheck %s

; Test LD.HU instruction - load halfword unsigned
; Requires V850E or later

; CHECK-LABEL: test_ldhu:
; CHECK: ld.hu
define i32 @test_ldhu(ptr %p) {
  %v = load i16, ptr %p
  %ext = zext i16 %v to i32
  ret i32 %ext
}

; CHECK-LABEL: test_ldhu_offset:
; CHECK: ld.hu {{[0-9]+}}[r{{[0-9]+}}]
define i32 @test_ldhu_offset(ptr %p) {
  %ptr = getelementptr i16, ptr %p, i32 5
  %v = load i16, ptr %ptr
  %ext = zext i16 %v to i32
  ret i32 %ext
}
