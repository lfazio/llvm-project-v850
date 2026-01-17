; RUN: llc -mtriple=v850 -O2 < %s | FileCheck %s --check-prefix=V850
; RUN: llc -mtriple=v850 -mcpu=v850e2 -O2 < %s | FileCheck %s --check-prefix=V850E2

; Test saturating arithmetic patterns
; V850 has SATADD/SATSUB/SATSUBI/SATSUBR instructions for signed saturating arithmetic
; These are available on all V850 variants (base V850 and later)

declare i32 @llvm.sadd.sat.i32(i32, i32)
declare i32 @llvm.ssub.sat.i32(i32, i32)
declare i32 @llvm.v850.satsubr(i32, i32)

;============================================================================
; Signed Saturating Add (saddsat)
;============================================================================

; Base V850 uses 2-operand form, V850E2+ uses 3-operand form
; V850: sat_add:
; V850:       satadd r7, r6
; V850E2: sat_add:
; V850E2:     satadd r7, r6, r10
define i32 @sat_add(i32 %a, i32 %b) {
entry:
  %result = call i32 @llvm.sadd.sat.i32(i32 %a, i32 %b)
  ret i32 %result
}

; Test with 5-bit immediate (-16 to 15)
; V850: sat_add_imm5:
; V850:       satadd 10, r6
; V850E2: sat_add_imm5:
; V850E2:     satadd 10, r6
define i32 @sat_add_imm5(i32 %a) {
entry:
  %result = call i32 @llvm.sadd.sat.i32(i32 %a, i32 10)
  ret i32 %result
}

; Test with negative 5-bit immediate
; V850: sat_add_neg_imm5:
; V850:       satadd -5, r6
; V850E2: sat_add_neg_imm5:
; V850E2:     satadd -5, r6
define i32 @sat_add_neg_imm5(i32 %a) {
entry:
  %result = call i32 @llvm.sadd.sat.i32(i32 %a, i32 -5)
  ret i32 %result
}

;============================================================================
; Signed Saturating Subtract (ssubsat)
;============================================================================

; Base V850 uses 2-operand form, V850E2+ uses 3-operand form
; V850: sat_sub:
; V850:       satsub r7, r6
; V850E2: sat_sub:
; V850E2:     satsub r7, r6, r10
define i32 @sat_sub(i32 %a, i32 %b) {
entry:
  %result = call i32 @llvm.ssub.sat.i32(i32 %a, i32 %b)
  ret i32 %result
}

; Test with 16-bit immediate (uses SATSUBI - available on all V850)
; V850: sat_sub_imm16:
; V850:       satsubi 1000, r6, r10
; V850E2: sat_sub_imm16:
; V850E2:     satsubi 1000, r6, r10
define i32 @sat_sub_imm16(i32 %a) {
entry:
  %result = call i32 @llvm.ssub.sat.i32(i32 %a, i32 1000)
  ret i32 %result
}

; Test with negative immediate
; V850: sat_sub_neg_imm:
; V850:       satsubi -500, r6, r10
; V850E2: sat_sub_neg_imm:
; V850E2:     satsubi -500, r6, r10
define i32 @sat_sub_neg_imm(i32 %a) {
entry:
  %result = call i32 @llvm.ssub.sat.i32(i32 %a, i32 -500)
  ret i32 %result
}

;============================================================================
; Signed Saturating Subtract Reverse (SATSUBR)
; SATSUBR computes saturate(a - b) using the intrinsic
;============================================================================

; V850: sat_sub_reverse:
; V850:       satsubr r6, r7
; V850E2: sat_sub_reverse:
; V850E2:     satsubr r6, r7
define i32 @sat_sub_reverse(i32 %a, i32 %b) {
entry:
  %result = call i32 @llvm.v850.satsubr(i32 %a, i32 %b)
  ret i32 %result
}
