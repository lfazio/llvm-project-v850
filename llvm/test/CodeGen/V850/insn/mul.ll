; RUN: llc -march=v850 -mcpu=v850e1 -O0 < %s | FileCheck %s

; Test MUL instruction (32x32->64 signed multiply) via inline assembly
; MUL is a V850E1+ instruction

; CHECK-LABEL: test_mul:
; CHECK: mul r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define void @test_mul() {
  call void asm sideeffect "mul r1, r2, r3", ""()
  ret void
}

