; RUN: llc -march=v850 -mcpu=v850e2 -O2 < %s | FileCheck %s

; Test SCH0L instruction - search zero from left (count leading ones)
; Requires V850E2 or later

; CHECK-LABEL: test_sch0l:
; CHECK: sch0l r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_sch0l(i32 %a) {
  %not = xor i32 %a, -1
  ; Use is_zero_poison=true to get direct pattern match
  %result = call i32 @llvm.ctlz.i32(i32 %not, i1 true)
  ret i32 %result
}

declare i32 @llvm.ctlz.i32(i32, i1)
