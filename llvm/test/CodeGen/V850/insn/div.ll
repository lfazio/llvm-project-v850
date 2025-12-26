; RUN: llc -march=v850 -mcpu=v850e1 -O0 < %s | FileCheck %s

; Test DIV instruction (signed 32-bit divide) via inline assembly
; DIV is a V850E1+ instruction that produces quotient and remainder

; CHECK-LABEL: test_div:
; CHECK: div r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define void @test_div() {
  call void asm sideeffect "div r1, r2, r3", ""()
  ret void
}

