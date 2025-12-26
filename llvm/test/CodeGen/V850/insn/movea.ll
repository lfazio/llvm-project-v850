; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test MOVEA instruction - move with 16-bit immediate

; CHECK-LABEL: test_movea:
; CHECK: movea {{-?[0-9]+}}, r0, r10
define i32 @test_movea() {
  ret i32 1000
}

; CHECK-LABEL: test_movea_neg:
; CHECK: movea {{-?[0-9]+}}, r0, r10
define i32 @test_movea_neg() {
  ret i32 -1000
}

; CHECK-LABEL: test_movea_max:
; CHECK: movea {{-?[0-9]+}}, r0, r10
define i32 @test_movea_max() {
  ret i32 32767
}

; CHECK-LABEL: test_movea_min:
; CHECK: movea {{-?[0-9]+}}, r0, r10
define i32 @test_movea_min() {
  ret i32 -32768
}

