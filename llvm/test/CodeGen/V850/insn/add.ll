; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test ADD instruction

; CHECK-LABEL: test_add:
; CHECK: add r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_add(i32 %a, i32 %b) {
  %result = add i32 %a, %b
  ret i32 %result
}

; CHECK-LABEL: test_addi5:
; CHECK: add {{-?[0-9]+}}, r{{[0-9]+}}
define i32 @test_addi5(i32 %a) {
  %result = add i32 %a, 5
  ret i32 %result
}

; CHECK-LABEL: test_addi16:
; CHECK: addi {{-?[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
define i32 @test_addi16(i32 %a) {
  %result = add i32 %a, 1000
  ret i32 %result
}
