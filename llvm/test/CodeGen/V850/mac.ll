; RUN: llc -march=v850 -mcpu=v850e2m < %s | FileCheck %s

; Test signed multiply-accumulate pattern:
; acc + (sext(a) * sext(b))

; CHECK-LABEL: mac_signed:
; CHECK: mac r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define i64 @mac_signed(i32 %a, i32 %b, i64 %acc) {
entry:
  %sext_a = sext i32 %a to i64
  %sext_b = sext i32 %b to i64
  %mul = mul i64 %sext_a, %sext_b
  %result = add i64 %acc, %mul
  ret i64 %result
}

; Test unsigned multiply-accumulate pattern:
; acc + (zext(a) * zext(b))

; CHECK-LABEL: macu_unsigned:
; CHECK: macu r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define i64 @macu_unsigned(i32 %a, i32 %b, i64 %acc) {
entry:
  %zext_a = zext i32 %a to i64
  %zext_b = zext i32 %b to i64
  %mul = mul i64 %zext_a, %zext_b
  %result = add i64 %acc, %mul
  ret i64 %result
}

; Test without MAC pattern - just multiply (no accumulation)
; Should use regular mul

; CHECK-LABEL: mul_only:
; CHECK: mul r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
; CHECK-NOT: mac
define i64 @mul_only(i32 %a, i32 %b) {
entry:
  %sext_a = sext i32 %a to i64
  %sext_b = sext i32 %b to i64
  %mul = mul i64 %sext_a, %sext_b
  ret i64 %mul
}
