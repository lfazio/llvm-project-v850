; RUN: llc -mtriple=v850 -mcpu=v850e2m < %s | FileCheck %s --check-prefix=E2M
; RUN: llc -mtriple=v850 -mcpu=v850e1 < %s | FileCheck %s --check-prefix=E1

;===----------------------------------------------------------------------===;
; Test 64-bit addition and subtraction
;
; V850E2+ uses ADF/SBF instructions for efficient 64-bit arithmetic:
; - ADF C, reg1, reg2, reg3: reg3 = reg2 + reg1 + (C ? 1 : 0)
; - SBF C, reg1, reg2, reg3: reg3 = reg2 - reg1 - (C ? 1 : 0)
;
; V850E1 and earlier use setf + add sequence (less efficient)
;===----------------------------------------------------------------------===;

; Test 64-bit addition
; E2M should use: add (sets C flag) + adf c
; E1 should use: add + setf c + add + add

; E2M-LABEL: add_i64:
; E2M:       add r{{[0-9]+}}, r{{[0-9]+}}
; E2M:       adf c, r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
; E2M:       jmp [r31]

; E1-LABEL: add_i64:
; E1:       add
; E1:       setf c
; E1:       add
define i64 @add_i64(i64 %a, i64 %b) {
entry:
  %result = add i64 %a, %b
  ret i64 %result
}

; Test 64-bit subtraction
; E2M should use: sub (sets C flag) + sbf c
; E1 should use: sub + setf c + sub + sub

; E2M-LABEL: sub_i64:
; E2M:       sub r{{[0-9]+}}, r{{[0-9]+}}
; E2M:       sbf c, r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
; E2M:       jmp [r31]

; E1-LABEL: sub_i64:
; E1:       sub
; E1:       setf
define i64 @sub_i64(i64 %a, i64 %b) {
entry:
  %result = sub i64 %a, %b
  ret i64 %result
}

; Test 64-bit addition with constants (one operand is constant)
; E2M-LABEL: add_i64_const:
; E2M:       add
; E2M:       adf c
define i64 @add_i64_const(i64 %a) {
entry:
  %result = add i64 %a, 12345678901234
  ret i64 %result
}

; Test chained 64-bit operations (128-bit add)
; This tests that the carry flags chain properly through multiple ADF instructions
; E2M-LABEL: add_i128:
; E2M:       add
; E2M:       adf c
; E2M:       adf c
; E2M:       adf c
define i128 @add_i128(i128 %a, i128 %b) {
entry:
  %result = add i128 %a, %b
  ret i128 %result
}
