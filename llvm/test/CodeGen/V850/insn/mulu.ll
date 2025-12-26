; RUN: llc -march=v850 -mcpu=v850e1 -O0 < %s | FileCheck %s

; Test MULU instruction code generation
; MULU is a V850E1+ instruction for unsigned 32-bit multiply
; Used for mulhu (high bits of unsigned multiply)

; CHECK-LABEL: test_mulhu:
; CHECK: mulu r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_mulhu(i32 %a, i32 %b) {
  %a64 = zext i32 %a to i64
  %b64 = zext i32 %b to i64
  %mul = mul i64 %a64, %b64
  %hi = lshr i64 %mul, 32
  %result = trunc i64 %hi to i32
  ret i32 %result
}

