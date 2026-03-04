; RUN: %if v850-registered-target %{ llc -mtriple=v850 -mcpu=g3m -O2 < %s | FileCheck %s %}

; Test that hardware loop intrinsics are lowered and then converted to the
; LOOP instruction by V850HardwareLoopPass on RH850G3M+.

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
