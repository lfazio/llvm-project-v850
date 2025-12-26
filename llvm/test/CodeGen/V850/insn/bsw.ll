; RUN: llc -march=v850 -mcpu=v850e1 -O0 < %s | FileCheck %s

; Test BSW instruction - byte swap word
; Requires V850E or later

; CHECK-LABEL: test_bsw:
; CHECK: bsw r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_bsw(i32 %a) {
  %bswap = call i32 @llvm.bswap.i32(i32 %a)
  ret i32 %bswap
}

declare i32 @llvm.bswap.i32(i32)
