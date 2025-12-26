; RUN: llc -march=v850 -mcpu=v850e1 -O0 < %s | FileCheck %s

; Test ZXH instruction - zero extend halfword (AND with 0xFFFF)
; Requires V850E or later

; CHECK-LABEL: test_zxh:
; CHECK: zxh r{{[0-9]+}}
define i32 @test_zxh(i32 %a) {
  %and = and i32 %a, 65535
  ret i32 %and
}

; CHECK-LABEL: test_zxh_trunc:
; CHECK: zxh r{{[0-9]+}}
define i32 @test_zxh_trunc(i32 %a) {
  %trunc = trunc i32 %a to i16
  %zext = zext i16 %trunc to i32
  ret i32 %zext
}
