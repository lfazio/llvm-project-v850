; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test DI instruction (disable interrupts) via inline assembly

; CHECK-LABEL: test_di:
; CHECK: di
define void @test_di() {
  call void asm sideeffect "di", ""()
  ret void
}

