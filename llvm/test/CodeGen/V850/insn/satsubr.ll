; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test SATSUBR instruction - saturating subtract reverse via inline assembly

; CHECK-LABEL: test_satsubr:
; CHECK: satsubr r{{[0-9]+}}, r{{[0-9]+}}
define void @test_satsubr() {
  call void asm sideeffect "satsubr r1, r2", ""()
  ret void
}

