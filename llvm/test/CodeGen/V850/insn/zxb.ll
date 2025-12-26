; RUN: llc -march=v850 -mcpu=v850e1 -O0 < %s | FileCheck %s

; Test ZXB instruction - zero extend byte (AND with 0xFF)
; Requires V850E1 or later

; CHECK-LABEL: test_zxb:
; CHECK: zxb r{{[0-9]+}}
define i32 @test_zxb(i32 %a) {
  %and = and i32 %a, 255
  ret i32 %and
}

; CHECK-LABEL: test_zxb_trunc:
; CHECK: zxb r{{[0-9]+}}
define i32 @test_zxb_trunc(i32 %a) {
  %trunc = trunc i32 %a to i8
  %zext = zext i8 %trunc to i32
  ret i32 %zext
}
