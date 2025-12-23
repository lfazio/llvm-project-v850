; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test constant materialization for small constants (5-bit signed)

; Test small positive constant
; CHECK-LABEL: const_small_pos:
; CHECK: mov 15, r10
; CHECK: jmp [lp]
define i32 @const_small_pos() {
  ret i32 15
}

; Test zero
; CHECK-LABEL: const_zero:
; CHECK: mov 0, r10
; CHECK: jmp [lp]
define i32 @const_zero() {
  ret i32 0
}

; Test small negative constant
; CHECK-LABEL: const_small_neg:
; CHECK: mov -16, r10
; CHECK: jmp [lp]
define i32 @const_small_neg() {
  ret i32 -16
}

; Test -1 (all ones)
; CHECK-LABEL: const_minus1:
; CHECK: mov -1, r10
; CHECK: jmp [lp]
define i32 @const_minus1() {
  ret i32 -1
}

; Test 1
; CHECK-LABEL: const_one:
; CHECK: mov 1, r10
; CHECK: jmp [lp]
define i32 @const_one() {
  ret i32 1
}

; Test -2
; CHECK-LABEL: const_minus2:
; CHECK: mov -2, r10
; CHECK: jmp [lp]
define i32 @const_minus2() {
  ret i32 -2
}
