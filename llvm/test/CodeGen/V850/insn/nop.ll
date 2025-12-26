; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test NOP instruction via inline assembly

; CHECK-LABEL: test_nop:
; CHECK: nop
define void @test_nop() {
  call void asm sideeffect "nop", ""()
  ret void
}

; CHECK-LABEL: test_nop_multiple:
; CHECK: nop
; CHECK: nop
; CHECK: nop
define void @test_nop_multiple() {
  call void asm sideeffect "nop", ""()
  call void asm sideeffect "nop", ""()
  call void asm sideeffect "nop", ""()
  ret void
}

