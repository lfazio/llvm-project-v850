; RUN: llc -mtriple=v850 -mcpu=v850e2m < %s | FileCheck %s

; Test function alignment optimization.
; V850 uses:
; - 2-byte minimum alignment (for 16-bit instructions)
; - 4-byte preferred alignment (for better 32-bit instruction fetch)
;
; When optimizing for size (-Os), functions use minimum alignment.
; Default functions use preferred alignment for better performance.

; Normal function should have 4-byte alignment (preferred)
; CHECK: .globl normal_function
; CHECK-NEXT: .p2align 2
; CHECK: normal_function:
define i32 @normal_function(i32 %a, i32 %b) {
  %result = add i32 %a, %b
  ret i32 %result
}

; Optimize-for-size function should have 2-byte alignment (minimum)
; CHECK: .globl optsize_function
; CHECK-NEXT: .p2align 1
; CHECK: optsize_function:
define i32 @optsize_function(i32 %a, i32 %b) optsize {
  %result = add i32 %a, %b
  ret i32 %result
}

; Another normal function to verify alignment is consistent
; CHECK: .globl multiple_functions
; CHECK-NEXT: .p2align 2
; CHECK: multiple_functions:
define i32 @multiple_functions(i32 %x) {
  %result = mul i32 %x, 2
  ret i32 %result
}

; Optsize function with loop - still uses minimum alignment
; CHECK: .globl optsize_with_loop
; CHECK-NEXT: .p2align 1
; CHECK: optsize_with_loop:
define i32 @optsize_with_loop(i32 %n) optsize {
entry:
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  %i.next = add i32 %i, 1
  %cond = icmp slt i32 %i.next, %n
  br i1 %cond, label %loop, label %exit

exit:
  ret i32 %i
}
