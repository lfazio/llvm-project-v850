; RUN: llc -march=v850 -mcpu=v850e1 -O0 < %s | FileCheck %s

; Test MUL instruction code generation for mulhs
; MUL is used for getting high bits of signed multiply

; CHECK-LABEL: test_mulhs:
; CHECK: mul r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_mulhs(i32 %a, i32 %b) {
  %a64 = sext i32 %a to i64
  %b64 = sext i32 %b to i64
  %mul = mul i64 %a64, %b64
  %hi = lshr i64 %mul, 32
  %result = trunc i64 %hi to i32
  ret i32 %result
}

