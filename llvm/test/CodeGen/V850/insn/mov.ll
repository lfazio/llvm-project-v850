; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test MOV instruction - move/immediate

; Test small immediate (5-bit signed)
; CHECK-LABEL: test_mov_imm5:
; CHECK: mov 10, r10
define i32 @test_mov_imm5() {
  ret i32 10
}

; Test 16-bit immediate via MOVEA
; CHECK-LABEL: test_mov_imm16:
; CHECK: movea {{-?[0-9]+}}, r0, r10
define i32 @test_mov_imm16() {
  ret i32 1000
}

; Test 32-bit immediate via MOVHI+MOVEA
; CHECK-LABEL: test_mov_imm32:
; CHECK: movhi
define i32 @test_mov_imm32() {
  ret i32 100000
}

; Test register move
; CHECK-LABEL: test_mov_reg:
; CHECK: mov r{{[0-9]+}}, r10
define i32 @test_mov_reg(i32 %a) {
  ret i32 %a
}
