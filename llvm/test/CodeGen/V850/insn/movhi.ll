; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test MOVHI instruction - move high 16 bits

; CHECK-LABEL: test_movhi:
; CHECK: movhi
define i32 @test_movhi() {
  ; 32-bit constant requires MOVHI + MOVEA
  ret i32 100000
}

; CHECK-LABEL: test_movhi_neg:
; CHECK: movhi
define i32 @test_movhi_neg() {
  ; Negative 32-bit constant
  ret i32 -100000
}
