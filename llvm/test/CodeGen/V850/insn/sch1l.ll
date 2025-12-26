; RUN: llc -march=v850 -mcpu=v850e2 -O2 < %s | FileCheck %s

; Test SCH1L instruction - search one from left (count leading zeros)
; Requires V850E2 or later

; CHECK-LABEL: test_sch1l:
; CHECK: sch1l r{{[0-9]+}}, r10
define i32 @test_sch1l(i32 %a) {
  %result = call i32 @llvm.ctlz.i32(i32 %a, i1 false)
  ret i32 %result
}

declare i32 @llvm.ctlz.i32(i32, i1)
