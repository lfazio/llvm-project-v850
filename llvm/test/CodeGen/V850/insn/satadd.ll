; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test SATADD instruction - saturating add via inline assembly

; CHECK-LABEL: test_satadd:
; CHECK: satadd r{{[0-9]+}}, r{{[0-9]+}}
define void @test_satadd() {
  call void asm sideeffect "satadd r1, r2", ""()
  ret void
}

