; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test SUBR instruction - subtract reverse (reg1 - reg2 -> reg2)

; CHECK-LABEL: test_subr:
; CHECK: subr r{{[0-9]+}}, r{{[0-9]+}}
define void @test_subr() {
  call void asm sideeffect "subr r1, r2", ""()
  ret void
}

