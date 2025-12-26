; RUN: llc -march=v850 -mcpu=v850e1 -O0 < %s | FileCheck %s

; Test LD.BU instruction - load byte unsigned
; Requires V850E or later

; CHECK-LABEL: test_ldbu:
; CHECK: ld.bu
define i32 @test_ldbu(ptr %p) {
  %v = load i8, ptr %p
  %ext = zext i8 %v to i32
  ret i32 %ext
}

; CHECK-LABEL: test_ldbu_offset:
; CHECK: ld.bu {{[0-9]+}}[r{{[0-9]+}}]
define i32 @test_ldbu_offset(ptr %p) {
  %ptr = getelementptr i8, ptr %p, i32 10
  %v = load i8, ptr %ptr
  %ext = zext i8 %v to i32
  ret i32 %ext
}
