; RUN: %if v850-registered-target %{ llc -mtriple=v850 -mcpu=g3m -O2 < %s | FileCheck %s %}

; Test that the V850HardwareLoopPass converts ADD -1 + CMP 0 + BNZ patterns
; into the LOOP instruction on RH850G3M+.

; Simple counted loop that stores values 0..n-1 to an array.
define void @counted_loop(ptr %p, i32 %n) {
; CHECK-LABEL: counted_loop:
; CHECK:       .LBB0_2:
; CHECK:       loop r{{[0-9]+}}, .LBB0_2
; CHECK-NOT:   cmp 0,
entry:
  %cmp = icmp sgt i32 %n, 0
  br i1 %cmp, label %loop, label %exit

loop:
  %i = phi i32 [ 0, %entry ], [ %inc, %loop ]
  %ptr = getelementptr i32, ptr %p, i32 %i
  store i32 %i, ptr %ptr
  %inc = add nuw nsw i32 %i, 1
  %cond = icmp slt i32 %inc, %n
  br i1 %cond, label %loop, label %exit

exit:
  ret void
}

; Loop with accumulation (sum of array elements).
define i32 @sum_loop(ptr %p, i32 %n) {
; CHECK-LABEL: sum_loop:
; CHECK:       loop r{{[0-9]+}}, .LBB1_
; CHECK-NOT:   cmp 0,
entry:
  %cmp = icmp sgt i32 %n, 0
  br i1 %cmp, label %loop, label %exit

loop:
  %i = phi i32 [ 0, %entry ], [ %inc, %loop ]
  %sum = phi i32 [ 0, %entry ], [ %add, %loop ]
  %ptr = getelementptr i32, ptr %p, i32 %i
  %val = load i32, ptr %ptr
  %add = add i32 %sum, %val
  %inc = add nuw nsw i32 %i, 1
  %cond = icmp slt i32 %inc, %n
  br i1 %cond, label %loop, label %exit

exit:
  %result = phi i32 [ 0, %entry ], [ %add, %loop ]
  ret i32 %result
}

; Memset-like loop (fill array with constant).
define void @memset_loop(ptr %p, i32 %val, i32 %n) {
; CHECK-LABEL: memset_loop:
; CHECK:       loop r{{[0-9]+}}, .LBB2_
; CHECK-NOT:   cmp 0,
entry:
  %cmp = icmp sgt i32 %n, 0
  br i1 %cmp, label %loop, label %exit

loop:
  %i = phi i32 [ 0, %entry ], [ %inc, %loop ]
  %ptr = getelementptr i32, ptr %p, i32 %i
  store i32 %val, ptr %ptr
  %inc = add nuw nsw i32 %i, 1
  %cond = icmp slt i32 %inc, %n
  br i1 %cond, label %loop, label %exit

exit:
  ret void
}
