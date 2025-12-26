; RUN: llc -march=v850 -mcpu=v850e1 -O0 < %s | FileCheck %s

; Test SXB instruction - sign extend byte
; Requires V850E1 or later

; CHECK-LABEL: test_sxb:
; CHECK: sxb r{{[0-9]+}}
define i32 @test_sxb(i32 %a) {
  %trunc = trunc i32 %a to i8
  %sext = sext i8 %trunc to i32
  ret i32 %sext
}
