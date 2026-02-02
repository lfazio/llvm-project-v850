; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m < %s | FileCheck %s --check-prefix=CHECK-E2M
; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850 < %s | FileCheck %s --check-prefix=CHECK-BASE

; Test that 16x16 signed multiply uses MULH instruction instead of MUL
; MULH is available on all V850 variants
; MUL (32x32) is only available on V850E1+

; Test with sign-extending loads from memory
define i32 @mul_i16_load(ptr %a, ptr %b) {
; CHECK-E2M-LABEL: mul_i16_load:
; CHECK-E2M:       ld.h 0[r{{[0-9]+}}], r{{[0-9]+}}
; CHECK-E2M:       ld.h 0[r{{[0-9]+}}], r{{[0-9]+}}
; CHECK-E2M:       mulh r{{[0-9]+}}, r{{[0-9]+}}
; CHECK-E2M-NOT:   mul r
; CHECK-BASE-LABEL: mul_i16_load:
; CHECK-BASE:       ld.h 0[r{{[0-9]+}}], r{{[0-9]+}}
; CHECK-BASE:       ld.h 0[r{{[0-9]+}}], r{{[0-9]+}}
; CHECK-BASE:       mulh r{{[0-9]+}}, r{{[0-9]+}}
; CHECK-BASE-NOT:   __mulsi3
  %va = load i16, ptr %a
  %vb = load i16, ptr %b
  %ea = sext i16 %va to i32
  %eb = sext i16 %vb to i32
  %mul = mul i32 %ea, %eb
  ret i32 %mul
}

; Test FIR filter pattern - key DSP use case for MULH
define i32 @fir_simple(ptr %coeffs, ptr %samples, i32 %n) {
; CHECK-E2M-LABEL: fir_simple:
; CHECK-E2M:       mulh r{{[0-9]+}}, r{{[0-9]+}}
; CHECK-E2M-NOT:   mul r{{[0-9]+}}, r{{[0-9]+}}, r
; CHECK-BASE-LABEL: fir_simple:
; CHECK-BASE:       mulh r{{[0-9]+}}, r{{[0-9]+}}
; CHECK-BASE-NOT:   __mulsi3
entry:
  %cmp = icmp sgt i32 %n, 0
  br i1 %cmp, label %for.body, label %exit

for.body:
  %i = phi i32 [ 0, %entry ], [ %i.next, %for.body ]
  %acc = phi i32 [ 0, %entry ], [ %acc.next, %for.body ]
  %cp = getelementptr i16, ptr %coeffs, i32 %i
  %sp = getelementptr i16, ptr %samples, i32 %i
  %c = load i16, ptr %cp
  %s = load i16, ptr %sp
  %ce = sext i16 %c to i32
  %se = sext i16 %s to i32
  %prod = mul i32 %ce, %se
  %acc.next = add i32 %acc, %prod
  %i.next = add i32 %i, 1
  %cond = icmp eq i32 %i.next, %n
  br i1 %cond, label %exit, label %for.body

exit:
  %result = phi i32 [ 0, %entry ], [ %acc.next, %for.body ]
  ret i32 %result
}

; Test that regular 32x32 multiply uses MUL on E2M, __mulsi3 on base
define i32 @mul_i32(i32 %a, i32 %b) {
; CHECK-E2M-LABEL: mul_i32:
; CHECK-E2M:       mul r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
; CHECK-E2M-NOT:   mulh
; CHECK-BASE-LABEL: mul_i32:
; CHECK-BASE:       __mulsi3
; CHECK-BASE-NOT:   mulh
  %mul = mul i32 %a, %b
  ret i32 %mul
}

; Test mixed case - one i16, one i32 should NOT use MULH (needs full 32-bit mul)
define i32 @mul_mixed(ptr %a, i32 %b) {
; CHECK-E2M-LABEL: mul_mixed:
; CHECK-E2M:       mul r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
; CHECK-E2M-NOT:   mulh
; CHECK-BASE-LABEL: mul_mixed:
; CHECK-BASE:       __mulsi3
; CHECK-BASE-NOT:   mulh
  %va = load i16, ptr %a
  %ea = sext i16 %va to i32
  %mul = mul i32 %ea, %b
  ret i32 %mul
}
