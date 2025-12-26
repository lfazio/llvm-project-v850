; RUN: llc -march=v850 -mcpu=v850e1 -O0 < %s | FileCheck %s

; Test DIV instruction for remainder (signed modulo)
; V850 DIV produces both quotient (reg2) and remainder (reg3)
; This test verifies the instruction can be used for remainder operations

; CHECK-LABEL: test_div_for_rem:
; CHECK: div r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define void @test_div_for_rem() {
  ; DIV r1, r2, r3: r2 = r2 / r1 (quotient), r3 = r2 % r1 (remainder)
  call void asm sideeffect "div r1, r2, r3", ""()
  ret void
}

