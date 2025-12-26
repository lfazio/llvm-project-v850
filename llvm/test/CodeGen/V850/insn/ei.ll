; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test EI instruction (enable interrupts) via inline assembly

; CHECK-LABEL: test_ei:
; CHECK: ei
define void @test_ei() {
  call void asm sideeffect "ei", ""()
  ret void
}

