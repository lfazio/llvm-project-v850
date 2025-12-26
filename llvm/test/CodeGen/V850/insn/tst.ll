; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test TST instruction - AND without storing result, sets flags

; CHECK-LABEL: test_tst:
; CHECK: tst r{{[0-9]+}}, r{{[0-9]+}}
define void @test_tst() {
  call void asm sideeffect "tst r1, r2", ""()
  ret void
}

