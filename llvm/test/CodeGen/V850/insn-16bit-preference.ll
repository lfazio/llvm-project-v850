; RUN: llc -march=v850 -mcpu=v850e1 < %s | FileCheck %s

; Test that 16-bit instruction forms are preferred over 32-bit forms
; when the immediate operand fits in the shorter form.

; ADD: small immediate should use 16-bit ADDi
define i32 @test_add_small(i32 %a) {
; CHECK-LABEL: test_add_small:
; CHECK: add 5, r6
; CHECK-NOT: addi 5
  %r = add i32 %a, 5
  ret i32 %r
}

; ADD: large immediate should use 32-bit ADDI
define i32 @test_add_large(i32 %a) {
; CHECK-LABEL: test_add_large:
; CHECK: addi 100, r6, r10
  %r = add i32 %a, 100
  ret i32 %r
}

; MOV: small constant should use 16-bit MOVi
define i32 @test_mov_small() {
; CHECK-LABEL: test_mov_small:
; CHECK: mov 10, r10
; CHECK-NOT: movea 10
  ret i32 10
}

; MOV: large constant should use 32-bit MOVEA
define i32 @test_mov_large() {
; CHECK-LABEL: test_mov_large:
; CHECK: movea 1000, r0, r10
  ret i32 1000
}

; SHR: immediate shift should use 16-bit SHRi
define i32 @test_shr(i32 %a) {
; CHECK-LABEL: test_shr:
; CHECK: shr 5, r6
  %r = lshr i32 %a, 5
  ret i32 %r
}

; SAR: immediate shift should use 16-bit SARi
define i32 @test_sar(i32 %a) {
; CHECK-LABEL: test_sar:
; CHECK: sar 8, r6
  %r = ashr i32 %a, 8
  ret i32 %r
}

; SHL: immediate shift should use 16-bit SHLi
define i32 @test_shl(i32 %a) {
; CHECK-LABEL: test_shl:
; CHECK: shl 3, r6
  %r = shl i32 %a, 3
  ret i32 %r
}

; Frame setup: small stack should use 16-bit add
define void @test_frame_small() {
; CHECK-LABEL: test_frame_small:
; CHECK: add -4, r3
; CHECK: add 4, r3
  %a = alloca i32
  store volatile i32 42, ptr %a
  ret void
}

; Frame setup: larger stack should use 32-bit addi
define void @test_frame_large() {
; CHECK-LABEL: test_frame_large:
; CHECK: addi -400, r3, r3
; CHECK: addi 400, r3, r3
  %a = alloca [100 x i32]
  %p = getelementptr [100 x i32], ptr %a, i32 0, i32 0
  store volatile i32 42, ptr %p
  ret void
}
