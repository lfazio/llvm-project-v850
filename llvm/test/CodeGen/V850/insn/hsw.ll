; RUN: llc -march=v850 -mcpu=v850e1 -O2 < %s | FileCheck %s

; Test HSW instruction - halfword swap (rotate by 16)
; Requires V850E1 or later

; CHECK-LABEL: test_hsw:
; CHECK: hsw r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_hsw(i32 %a) {
  %hi = lshr i32 %a, 16
  %lo = shl i32 %a, 16
  %swap = or i32 %hi, %lo
  ret i32 %swap
}
