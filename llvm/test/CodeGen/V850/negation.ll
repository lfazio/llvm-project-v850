; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850 < %s | FileCheck %s
; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m < %s | FileCheck %s

; Test that negation uses SUBR instruction instead of MOV+SUB

define i32 @negate_i32(i32 %a) {
; CHECK-LABEL: negate_i32:
; CHECK:       subr r0, r6
; CHECK-NEXT:  mov r6, r10
; CHECK-NEXT:  jmp [r31]
  %neg = sub i32 0, %a
  ret i32 %neg
}

; The optimizer transforms (-a) + b into b - a, which is correct
define i32 @negate_i32_used(i32 %a, i32 %b) {
; CHECK-LABEL: negate_i32_used:
; CHECK:       sub r6, r7
; CHECK:       mov r7, r10
; CHECK:       jmp [r31]
  %neg = sub i32 0, %a
  %sum = add i32 %neg, %b
  ret i32 %sum
}

; The optimizer simplifies -(-a) to just a
define i32 @negate_twice(i32 %a) {
; CHECK-LABEL: negate_twice:
; CHECK:       mov r6, r10
; CHECK:       jmp [r31]
  %neg1 = sub i32 0, %a
  %neg2 = sub i32 0, %neg1
  ret i32 %neg2
}

; Make sure regular subtraction still works
define i32 @subtract(i32 %a, i32 %b) {
; CHECK-LABEL: subtract:
; CHECK:       sub r7, r6
; CHECK:       mov r6, r10
; CHECK:       jmp [r31]
  %diff = sub i32 %a, %b
  ret i32 %diff
}

; Test negation in more complex context where it can't be optimized away
define i32 @negate_with_call(i32 %a) {
; CHECK-LABEL: negate_with_call:
; CHECK:       subr r0, r{{[0-9]+}}
  %neg = sub i32 0, %a
  call void @use(i32 %neg)
  ret i32 %neg
}

declare void @use(i32)
