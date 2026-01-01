; RUN: llc -march=v850 -mcpu=v850e1 < %s | FileCheck %s --check-prefix=CHECK-NO-FP
; RUN: llc -march=v850 -mcpu=v850e1 -frame-pointer=all < %s | FileCheck %s --check-prefix=CHECK-FP

; Test frame pointer elimination behavior
; Note: SP is register r3, FP is r29

; Simple leaf function - should not use frame pointer when eliminated
; CHECK-NO-FP-LABEL: simple_leaf:
; CHECK-NO-FP-NOT: mov r3, r29
; CHECK-NO-FP: add r{{[0-9]+}}, r{{[0-9]+}}
; CHECK-NO-FP: jmp [r31]

; CHECK-FP-LABEL: simple_leaf:
; CHECK-FP: mov r3, r29
; CHECK-FP: st.w r29
define i32 @simple_leaf(i32 %a, i32 %b) {
  %result = add i32 %a, %b
  ret i32 %result
}

; Function with local variables on stack
; CHECK-NO-FP-LABEL: with_locals:
; CHECK-NO-FP: addi -{{[0-9]+}}, r3, r3
; CHECK-NO-FP-NOT: mov r3, r29

; CHECK-FP-LABEL: with_locals:
; CHECK-FP: mov r3, r29
define i32 @with_locals(i32 %a) {
  %local = alloca i32, align 4
  store i32 %a, ptr %local
  %val = load i32, ptr %local
  ret i32 %val
}

; Function with variable-sized allocation (alloca) - always needs FP
; CHECK-NO-FP-LABEL: with_vla:
; CHECK-NO-FP: mov r3, r29

; CHECK-FP-LABEL: with_vla:
; CHECK-FP: mov r3, r29
define i32 @with_vla(i32 %n) {
  %vla = alloca i32, i32 %n, align 4
  store i32 42, ptr %vla
  %val = load i32, ptr %vla
  ret i32 %val
}

; Function that calls another function (non-leaf)
; CHECK-NO-FP-LABEL: non_leaf:
; CHECK-NO-FP: st.w r31
; CHECK-NO-FP-NOT: mov r3, r29
; CHECK-NO-FP: jarl

; CHECK-FP-LABEL: non_leaf:
; CHECK-FP: mov r3, r29
; CHECK-FP: st.w r31
declare i32 @external_func(i32)

define i32 @non_leaf(i32 %a) {
  %result = call i32 @external_func(i32 %a)
  ret i32 %result
}
