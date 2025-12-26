; RUN: llc -march=v850 -mcpu=v850e2 -O2 < %s | FileCheck %s

; Test SCH1R instruction - search one from right (count trailing zeros)
; Requires V850E2 or later

; CHECK-LABEL: test_sch1r:
; CHECK: sch1r r{{[0-9]+}}, r10
define i32 @test_sch1r(i32 %a) {
  %result = call i32 @llvm.cttz.i32(i32 %a, i1 false)
  ret i32 %result
}

declare i32 @llvm.cttz.i32(i32, i1)
