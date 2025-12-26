; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test RETI instruction via inline assembly

; CHECK-LABEL: test_reti:
; CHECK: reti
define void @test_reti() {
  call void asm sideeffect "reti", ""()
  ret void
}

