; RUN: llc -mtriple=v850 -mcpu=v850e2m < %s | FileCheck %s

; Test variable arguments (varargs) support.
; V850 uses r6-r9 for the first 4 arguments, rest on stack.

declare void @llvm.va_start(ptr)
declare void @llvm.va_end(ptr)
declare void @llvm.va_copy(ptr, ptr)

;; Test 1: Receiving varargs
; va_start stores the address of the varargs area into va_list
; CHECK-LABEL: varargs_receiver:
; CHECK:       add -4, r3
; CHECK:       addi 0, r3, r10
; CHECK:       addi 4, r3, r11
; CHECK:       st.w r11, 0[r10]
; CHECK:       mov r6, r10
; CHECK:       add 4, r3
; CHECK-NEXT:  jmp [r31]
define i32 @varargs_receiver(i32 %first, ...) {
entry:
  %va = alloca ptr, align 4
  call void @llvm.va_start(ptr %va)
  call void @llvm.va_end(ptr %va)
  ret i32 %first
}

;; Test 2: Varargs with multiple fixed arguments
; First 4 args in r6-r9, varargs start on stack
; CHECK-LABEL: varargs_four_fixed:
; CHECK:       add r7, r6
; CHECK:       add r8, r6
; CHECK:       add r9, r6
; CHECK:       mov r6, r10
; CHECK:       jmp [r31]
define i32 @varargs_four_fixed(i32 %a, i32 %b, i32 %c, i32 %d, ...) {
entry:
  %va = alloca ptr, align 4
  call void @llvm.va_start(ptr %va)
  %sum1 = add i32 %a, %b
  %sum2 = add i32 %sum1, %c
  %sum3 = add i32 %sum2, %d
  call void @llvm.va_end(ptr %va)
  ret i32 %sum3
}

;; Test 3: Calling a varargs function
; Arguments should be passed in r6, r7, r8
; CHECK-LABEL: call_varargs:
; CHECK:       movea .L.str, r4, r6
; CHECK:       mov 10, r7
; CHECK:       movea 20, r0, r8
; CHECK:       jarl external_varargs, r31
define i32 @call_varargs() {
  %result = call i32 (ptr, ...) @external_varargs(ptr @.str, i32 10, i32 20)
  ret i32 %result
}

declare i32 @external_varargs(ptr, ...)
@.str = private constant [6 x i8] c"hello\00"

;; Test 4: va_copy
; Both va_lists get the same value (pointer to varargs)
; CHECK-LABEL: test_va_copy:
; CHECK:       addi 0, r3, r10
; CHECK:       addi {{[0-9]+}}, r3, r11
; CHECK:       st.w r11, 0[r10]
; CHECK:       addi 4, r3, r10
; CHECK:       st.w r11, 0[r10]
; CHECK:       mov r6, r10
; CHECK:       jmp [r31]
define i32 @test_va_copy(i32 %first, ...) {
entry:
  %va1 = alloca ptr, align 4
  %va2 = alloca ptr, align 4
  call void @llvm.va_start(ptr %va1)
  call void @llvm.va_copy(ptr %va2, ptr %va1)
  call void @llvm.va_end(ptr %va1)
  call void @llvm.va_end(ptr %va2)
  ret i32 %first
}
