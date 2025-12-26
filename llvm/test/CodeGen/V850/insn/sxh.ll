; RUN: llc -march=v850 -mcpu=v850e1 -O0 < %s | FileCheck %s

; Test SXH instruction - sign extend halfword
; Requires V850E1 or later

; CHECK-LABEL: test_sxh:
; CHECK: sxh r{{[0-9]+}}
define i32 @test_sxh(i32 %a) {
  %trunc = trunc i32 %a to i16
  %sext = sext i16 %trunc to i32
  ret i32 %sext
}
