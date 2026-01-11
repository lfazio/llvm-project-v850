; RUN: llc -mtriple=v850 -mcpu=v850e2m < %s | FileCheck %s

;===----------------------------------------------------------------------===;
; Test saturating arithmetic instructions
;
; V850 provides native saturating add/subtract instructions:
; - SATADD reg1, reg2 / SATADD reg1, reg2, reg3
; - SATSUB reg1, reg2 / SATSUB reg1, reg2, reg3
; - SATADD imm5, reg2
; - SATSUBI imm16, reg1, reg2
;===----------------------------------------------------------------------===;

declare i32 @llvm.sadd.sat.i32(i32, i32)
declare i32 @llvm.ssub.sat.i32(i32, i32)

;===----------------------------------------------------------------------===;
; Saturating Add Tests
;===----------------------------------------------------------------------===;

; Test basic saturating add
; CHECK-LABEL: test_satadd:
; CHECK: satadd r7, r6
; CHECK: jmp [r31]
define i32 @test_satadd(i32 %a, i32 %b) {
entry:
  %result = call i32 @llvm.sadd.sat.i32(i32 %a, i32 %b)
  ret i32 %result
}

; Test saturating add with immediate (small positive)
; CHECK-LABEL: test_satadd_imm_pos:
; CHECK: satadd 10, r6
; CHECK: jmp [r31]
define i32 @test_satadd_imm_pos(i32 %a) {
entry:
  %result = call i32 @llvm.sadd.sat.i32(i32 %a, i32 10)
  ret i32 %result
}

; Test saturating add with immediate (small negative)
; CHECK-LABEL: test_satadd_imm_neg:
; CHECK: satadd -5, r6
; CHECK: jmp [r31]
define i32 @test_satadd_imm_neg(i32 %a) {
entry:
  %result = call i32 @llvm.sadd.sat.i32(i32 %a, i32 -5)
  ret i32 %result
}

;===----------------------------------------------------------------------===;
; Saturating Subtract Tests
;===----------------------------------------------------------------------===;

; Test basic saturating subtract
; CHECK-LABEL: test_satsub:
; CHECK: satsub r7, r6
; CHECK: jmp [r31]
define i32 @test_satsub(i32 %a, i32 %b) {
entry:
  %result = call i32 @llvm.ssub.sat.i32(i32 %a, i32 %b)
  ret i32 %result
}

; Test saturating subtract with immediate
; CHECK-LABEL: test_satsubi:
; CHECK: satsubi 1000, r6, r10
; CHECK: jmp [r31]
define i32 @test_satsubi(i32 %a) {
entry:
  %result = call i32 @llvm.ssub.sat.i32(i32 %a, i32 1000)
  ret i32 %result
}

;===----------------------------------------------------------------------===;
; Edge Case Tests
;===----------------------------------------------------------------------===;

; Test saturation at INT_MAX
; CHECK-LABEL: test_satadd_overflow:
; CHECK: satadd
define i32 @test_satadd_overflow(i32 %a) {
entry:
  %result = call i32 @llvm.sadd.sat.i32(i32 %a, i32 2147483647)
  ret i32 %result
}

; Test saturation at INT_MIN
; CHECK-LABEL: test_satsub_underflow:
; CHECK: satsub
define i32 @test_satsub_underflow(i32 %a) {
entry:
  %result = call i32 @llvm.ssub.sat.i32(i32 %a, i32 2147483647)
  ret i32 %result
}

;===----------------------------------------------------------------------===;
; Multiple Operations
;===----------------------------------------------------------------------===;

; Test chain of saturating operations
; CHECK-LABEL: test_satadd_chain:
; CHECK: satadd
; CHECK: satadd
define i32 @test_satadd_chain(i32 %a, i32 %b, i32 %c) {
entry:
  %t1 = call i32 @llvm.sadd.sat.i32(i32 %a, i32 %b)
  %t2 = call i32 @llvm.sadd.sat.i32(i32 %t1, i32 %c)
  ret i32 %t2
}

; Test mixed saturating add and subtract
; CHECK-LABEL: test_mixed_sat:
; CHECK: satadd
; CHECK: satsub
define i32 @test_mixed_sat(i32 %a, i32 %b, i32 %c) {
entry:
  %t1 = call i32 @llvm.sadd.sat.i32(i32 %a, i32 %b)
  %t2 = call i32 @llvm.ssub.sat.i32(i32 %t1, i32 %c)
  ret i32 %t2
}
