; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test RET instruction (return from function)

; CHECK-LABEL: test_ret_void:
; CHECK: jmp [r31]
define void @test_ret_void() {
  ret void
}

; CHECK-LABEL: test_ret_value:
; CHECK: movea 42, r0, r10
; CHECK: jmp [r31]
define i32 @test_ret_value() {
  ret i32 42
}

; CHECK-LABEL: test_ret_arg:
; CHECK: mov r{{[0-9]+}}, r10
; CHECK: jmp [r31]
define i32 @test_ret_arg(i32 %a) {
  ret i32 %a
}
