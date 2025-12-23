; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test V850 EABI calling convention
; Arguments: r6, r7, r8, r9
; Return: r10 (32-bit)

; Test that first argument comes in r6, return in r10
; CHECK-LABEL: return_first_arg:
; CHECK: mov r6, r10
; CHECK: jmp [lp]
define i32 @return_first_arg(i32 %a) {
  ret i32 %a
}

; Test that second argument comes in r7
; CHECK-LABEL: return_second_arg:
; CHECK: mov r7, r10
; CHECK: jmp [lp]
define i32 @return_second_arg(i32 %a, i32 %b) {
  ret i32 %b
}

; Test that third argument comes in r8
; CHECK-LABEL: return_third_arg:
; CHECK: mov r8, r10
; CHECK: jmp [lp]
define i32 @return_third_arg(i32 %a, i32 %b, i32 %c) {
  ret i32 %c
}

; Test that fourth argument comes in r9
; CHECK-LABEL: return_fourth_arg:
; CHECK: mov r9, r10
; CHECK: jmp [lp]
define i32 @return_fourth_arg(i32 %a, i32 %b, i32 %c, i32 %d) {
  ret i32 %d
}

; Test sum of two register arguments
; CHECK-LABEL: sum_two_args:
; CHECK: mov r6, r10
; CHECK: add r7, r10
; CHECK: jmp [lp]
define i32 @sum_two_args(i32 %a, i32 %b) {
  %sum = add i32 %a, %b
  ret i32 %sum
}

; Test returning zero
; CHECK-LABEL: return_zero:
; CHECK: mov 0, r10
; CHECK: jmp [lp]
define i32 @return_zero() {
  ret i32 0
}

; Test returning -1 (small constant)
; CHECK-LABEL: return_minus1:
; CHECK: mov -1, r10
; CHECK: jmp [lp]
define i32 @return_minus1() {
  ret i32 -1
}

; Test void function return
; CHECK-LABEL: return_void:
; CHECK: jmp [lp]
define void @return_void() {
  ret void
}
