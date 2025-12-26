; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test TRAP instruction via inline assembly

; CHECK-LABEL: test_trap:
; CHECK: trap 0
define void @test_trap() {
  call void asm sideeffect "trap 0", ""()
  ret void
}

; CHECK-LABEL: test_trap_vector:
; CHECK: trap 10
define void @test_trap_vector() {
  call void asm sideeffect "trap 10", ""()
  ret void
}

