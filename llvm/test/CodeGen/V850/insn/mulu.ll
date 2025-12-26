; RUN: llc -march=v850 -mcpu=v850e1 -O0 < %s | FileCheck %s

; Test MULU instruction (32x32->64 unsigned multiply) via inline assembly
; MULU is a V850E1+ instruction

; CHECK-LABEL: test_mulu:
; CHECK: mulu r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define void @test_mulu() {
  call void asm sideeffect "mulu r1, r2, r3", ""()
  ret void
}

