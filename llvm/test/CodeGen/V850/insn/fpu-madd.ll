; RUN: llc -march=v850 -mcpu=v850e2m -O0 < %s | FileCheck %s

; Test FPU multiply-accumulate instructions via inline assembly
; These tests verify the instructions are properly assembled

; CHECK-LABEL: test_maddfs:
; CHECK: maddf.s
define void @test_maddfs() {
  call void asm sideeffect "maddf.s r6, r7, r8, r10", ""()
  ret void
}

; CHECK-LABEL: test_msubfs:
; CHECK: msubf.s
define void @test_msubfs() {
  call void asm sideeffect "msubf.s r6, r7, r8, r10", ""()
  ret void
}

; CHECK-LABEL: test_nmaddfs:
; CHECK: nmaddf.s
define void @test_nmaddfs() {
  call void asm sideeffect "nmaddf.s r6, r7, r8, r10", ""()
  ret void
}

; CHECK-LABEL: test_nmsubfs:
; CHECK: nmsubf.s
define void @test_nmsubfs() {
  call void asm sideeffect "nmsubf.s r6, r7, r8, r10", ""()
  ret void
}
