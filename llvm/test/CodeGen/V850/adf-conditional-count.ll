; RUN: llc -mtriple=v850 -mcpu=v850e2m < %s | FileCheck %s
; RUN: llc -mtriple=v850 -mcpu=v850e1 < %s | FileCheck %s --check-prefix=CHECK-NOADF

;===----------------------------------------------------------------------===;
; Test ADF (Add on Condition Flag) instruction generation for conditional
; counting patterns: count += (a > b) ? 1 : 0
;
; ADF cccc, reg1, reg2, reg3: reg3 = reg2 + reg1 + (cond ? 1 : 0)
; With reg1=r0: reg3 = reg2 + (cond ? 1 : 0) — conditional increment.
;
; ADF is available on V850E2 and later. Saves 1 instruction vs setf+add.
;===----------------------------------------------------------------------===;

; CHECK-LABEL: count_gt:
; CHECK:       cmp r7, r6
; CHECK-NEXT:  adf gt, r0, r8, r10
; CHECK-NOADF-LABEL: count_gt:
; CHECK-NOADF-NOT:   adf
; CHECK-NOADF:       setf gt
; CHECK-NOADF:       add
define i32 @count_gt(i32 %a, i32 %b, i32 %count) {
  %cmp = icmp sgt i32 %a, %b
  %ext = zext i1 %cmp to i32
  %add = add i32 %count, %ext
  ret i32 %add
}

; CHECK-LABEL: count_lt:
; CHECK:       cmp r7, r6
; CHECK-NEXT:  adf lt, r0, r8, r10
define i32 @count_lt(i32 %a, i32 %b, i32 %count) {
  %cmp = icmp slt i32 %a, %b
  %ext = zext i1 %cmp to i32
  %add = add i32 %count, %ext
  ret i32 %add
}

; CHECK-LABEL: count_eq:
; CHECK:       cmp r7, r6
; CHECK-NEXT:  adf z, r0, r8, r10
define i32 @count_eq(i32 %a, i32 %b, i32 %count) {
  %cmp = icmp eq i32 %a, %b
  %ext = zext i1 %cmp to i32
  %add = add i32 %count, %ext
  ret i32 %add
}

; CHECK-LABEL: count_ne:
; CHECK:       cmp r7, r6
; CHECK-NEXT:  adf nz, r0, r8, r10
define i32 @count_ne(i32 %a, i32 %b, i32 %count) {
  %cmp = icmp ne i32 %a, %b
  %ext = zext i1 %cmp to i32
  %add = add i32 %count, %ext
  ret i32 %add
}

; CHECK-LABEL: count_ugt:
; CHECK:       cmp r7, r6
; CHECK-NEXT:  adf h, r0, r8, r10
define i32 @count_ugt(i32 %a, i32 %b, i32 %count) {
  %cmp = icmp ugt i32 %a, %b
  %ext = zext i1 %cmp to i32
  %add = add i32 %count, %ext
  ret i32 %add
}

; CHECK-LABEL: count_ult:
; CHECK:       cmp r7, r6
; CHECK-NEXT:  adf c, r0, r8, r10
define i32 @count_ult(i32 %a, i32 %b, i32 %count) {
  %cmp = icmp ult i32 %a, %b
  %ext = zext i1 %cmp to i32
  %add = add i32 %count, %ext
  ret i32 %add
}

; Reversed operand order: (add (zext (setcc)), count)
; CHECK-LABEL: count_gt_reverse:
; CHECK:       cmp r7, r6
; CHECK-NEXT:  adf gt, r0, r8, r10
define i32 @count_gt_reverse(i32 %a, i32 %b, i32 %count) {
  %cmp = icmp sgt i32 %a, %b
  %ext = zext i1 %cmp to i32
  %add = add i32 %ext, %count
  ret i32 %add
}

; Loop pattern: counting elements greater than threshold
; CHECK-LABEL: count_in_loop:
; CHECK:       adf
define i32 @count_in_loop(ptr %arr, i32 %n, i32 %threshold) {
entry:
  %cmp_n = icmp sgt i32 %n, 0
  br i1 %cmp_n, label %loop, label %exit

loop:
  %i = phi i32 [0, %entry], [%i.next, %loop]
  %count = phi i32 [0, %entry], [%count.next, %loop]
  %ptr = getelementptr i32, ptr %arr, i32 %i
  %val = load i32, ptr %ptr
  %cmp = icmp sgt i32 %val, %threshold
  %inc = zext i1 %cmp to i32
  %count.next = add i32 %count, %inc
  %i.next = add i32 %i, 1
  %done = icmp eq i32 %i.next, %n
  br i1 %done, label %exit, label %loop

exit:
  %result = phi i32 [0, %entry], [%count.next, %loop]
  ret i32 %result
}
