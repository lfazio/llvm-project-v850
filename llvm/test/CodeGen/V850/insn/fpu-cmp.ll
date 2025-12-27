; RUN: llc -march=v850 -mcpu=v850e2m -O0 < %s | FileCheck %s

; Test FPU comparison instructions via inline assembly
; These tests verify the instructions are properly assembled

; CHECK-LABEL: test_cmpfs:
; CHECK: cmpf.s
define void @test_cmpfs() {
  call void asm sideeffect "cmpf.s eq, r6, r7, 0", ""()
  ret void
}

; CHECK-LABEL: test_cmpfd:
; CHECK: cmpf.d
define void @test_cmpfd() {
  call void asm sideeffect "cmpf.d eq, r6, r8, 0", ""()
  ret void
}

; CHECK-LABEL: test_trfsr:
; CHECK: trfsr
define void @test_trfsr() {
  call void asm sideeffect "trfsr 0", ""()
  ret void
}
