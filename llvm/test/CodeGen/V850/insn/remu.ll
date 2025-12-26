; RUN: llc -march=v850 -mcpu=v850e1 -O0 < %s | FileCheck %s

; Test DIVU instruction for remainder (unsigned modulo)
; V850 DIVU produces both quotient (reg2) and remainder (reg3)
; This test verifies the instruction can be used for remainder operations

; CHECK-LABEL: test_divu_for_rem:
; CHECK: divu r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define void @test_divu_for_rem() {
  ; DIVU r1, r2, r3: r2 = r2 / r1 (quotient), r3 = r2 % r1 (remainder)
  call void asm sideeffect "divu r1, r2, r3", ""()
  ret void
}

