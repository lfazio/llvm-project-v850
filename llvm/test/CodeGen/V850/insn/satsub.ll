; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test SATSUB instruction - saturating subtract via inline assembly

; CHECK-LABEL: test_satsub:
; CHECK: satsub r{{[0-9]+}}, r{{[0-9]+}}
define void @test_satsub() {
  call void asm sideeffect "satsub r1, r2", ""()
  ret void
}

