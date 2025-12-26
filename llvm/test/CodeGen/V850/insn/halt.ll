; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test HALT instruction via inline assembly

; CHECK-LABEL: test_halt:
; CHECK: halt
define void @test_halt() {
  call void asm sideeffect "halt", ""()
  ret void
}

