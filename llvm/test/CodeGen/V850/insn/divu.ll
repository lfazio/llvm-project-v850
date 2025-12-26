; RUN: llc -march=v850 -mcpu=v850e1 -O0 < %s | FileCheck %s

; Test DIVU instruction (unsigned 32-bit divide) via inline assembly
; DIVU is a V850E1+ instruction that produces quotient and remainder

; CHECK-LABEL: test_divu:
; CHECK: divu r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define void @test_divu() {
  call void asm sideeffect "divu r1, r2, r3", ""()
  ret void
}

