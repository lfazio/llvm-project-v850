; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test LD.B instruction - load byte (sign-extended)

; CHECK-LABEL: test_ldb:
; CHECK: ld.b 0[r{{[0-9]+}}], r{{[0-9]+}}
define i32 @test_ldb(ptr %p) {
  %v = load i8, ptr %p
  %ext = sext i8 %v to i32
  ret i32 %ext
}

; CHECK-LABEL: test_ldb_offset:
; CHECK: ld.b {{[0-9]+}}[r{{[0-9]+}}], r{{[0-9]+}}
define i32 @test_ldb_offset(ptr %p) {
  %ptr = getelementptr i8, ptr %p, i32 10
  %v = load i8, ptr %ptr
  %ext = sext i8 %v to i32
  ret i32 %ext
}
