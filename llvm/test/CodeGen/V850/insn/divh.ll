; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test DIVH instruction - divide halfword via inline assembly

; CHECK-LABEL: test_divh:
; CHECK: divh r{{[0-9]+}}, r{{[0-9]+}}
define void @test_divh() {
  call void asm sideeffect "divh r1, r2", ""()
  ret void
}

