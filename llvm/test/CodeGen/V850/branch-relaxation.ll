; RUN: llc -march=v850 -mcpu=v850e1 < %s | FileCheck %s

; Test branch analysis and insertion for V850.
; Verify that conditional branches are generated correctly for various conditions.

; Test equality comparison branch (inverted to bnz for fallthrough)
define i32 @branch_eq(i32 %a, i32 %b) {
; CHECK-LABEL: branch_eq:
; CHECK: bnz
entry:
  %cmp = icmp eq i32 %a, %b
  br i1 %cmp, label %then, label %else

then:
  ret i32 1

else:
  ret i32 0
}

; Test signed less than branch (inverted to bge for fallthrough)
define i32 @branch_slt(i32 %a, i32 %b) {
; CHECK-LABEL: branch_slt:
; CHECK: bge
entry:
  %cmp = icmp slt i32 %a, %b
  br i1 %cmp, label %then, label %else

then:
  ret i32 1

else:
  ret i32 0
}

; Test unsigned less than branch (inverted to bnc for fallthrough)
define i32 @branch_ult(i32 %a, i32 %b) {
; CHECK-LABEL: branch_ult:
; CHECK: bnc
entry:
  %cmp = icmp ult i32 %a, %b
  br i1 %cmp, label %then, label %else

then:
  ret i32 1

else:
  ret i32 0
}

; Test greater than branch (inverted to ble for fallthrough)
define i32 @branch_sgt(i32 %a, i32 %b) {
; CHECK-LABEL: branch_sgt:
; CHECK: ble
entry:
  %cmp = icmp sgt i32 %a, %b
  br i1 %cmp, label %then, label %else

then:
  ret i32 1

else:
  ret i32 0
}
