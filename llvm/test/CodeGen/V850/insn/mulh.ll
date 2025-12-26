; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test MULH instruction - multiply halfword via inline assembly

; CHECK-LABEL: test_mulh:
; CHECK: mulh r{{[0-9]+}}, r{{[0-9]+}}
define void @test_mulh() {
  call void asm sideeffect "mulh r1, r2", ""()
  ret void
}

