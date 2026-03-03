; RUN: %if v850-registered-target %{ llc -mtriple=v850 -mcpu=g3m -O2 -stop-after=hardware-loops < %s | FileCheck %s %}

; Test that the HardwareLoops pass converts counted loops to hardware loop
; intrinsics when targeting RH850G3M+ (with CounterInReg = true).

define void @simple_loop(ptr %p, i32 %n) {
; CHECK-LABEL: @simple_loop
; CHECK: call i32 @llvm.start.loop.iterations.i32(i32 %n)
; CHECK: call i32 @llvm.loop.decrement.reg.i32(i32
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

; Verify that hardware loops are NOT generated for base V850E2M (no LOOP instruction).
; RUN: %if v850-registered-target %{ llc -mtriple=v850 -mcpu=v850e2m -O2 -stop-after=hardware-loops < %s | FileCheck %s --check-prefix=NO-HWLOOP %}

; NO-HWLOOP-LABEL: @simple_loop
; NO-HWLOOP-NOT: @llvm.start.loop.iterations
; NO-HWLOOP-NOT: @llvm.loop.decrement.reg
