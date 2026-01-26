; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m < %s | FileCheck %s

; Test V850 calling convention:
; - Arguments in r6-r9, then stack
; - Return value in r10 (32-bit)
; - Callee-saved: r20-r29, EP (r30), LP (r31)

;-----------------------------------------------------------------------------
; Basic argument passing - 4 i32 arguments in registers
;-----------------------------------------------------------------------------

define i32 @test_args4(i32 %a, i32 %b, i32 %c, i32 %d) {
; CHECK-LABEL: test_args4:
; Arguments in r6, r7, r8, r9
; CHECK:       add r{{[0-9]+}}, r{{[0-9]+}}
  %sum1 = add i32 %a, %b
  %sum2 = add i32 %sum1, %c
  %sum3 = add i32 %sum2, %d
  ret i32 %sum3
}

;-----------------------------------------------------------------------------
; 5th argument passed on stack
;-----------------------------------------------------------------------------

define i32 @test_args5(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e) {
; CHECK-LABEL: test_args5:
; 5th argument loaded from stack
; CHECK:       ld.w {{[0-9]+}}[r{{[0-9]+}}], r{{[0-9]+}}
  %sum = add i32 %a, %e
  ret i32 %sum
}

;-----------------------------------------------------------------------------
; Return i32 in r10
;-----------------------------------------------------------------------------

define i32 @test_return_i32(i32 %x) {
; CHECK-LABEL: test_return_i32:
; Return value should be in r10
; CHECK:       mov r6, r10
; CHECK:       jmp [r31]
  ret i32 %x
}

;-----------------------------------------------------------------------------
; Float argument (passed in GPR)
;-----------------------------------------------------------------------------

define float @test_float_arg(float %f) {
; CHECK-LABEL: test_float_arg:
; Float is passed in r6 (as bit pattern)
; CHECK:       mov r6, r10
  ret float %f
}

;-----------------------------------------------------------------------------
; Varargs function
;-----------------------------------------------------------------------------

declare void @llvm.va_start(ptr)
declare void @llvm.va_end(ptr)

define i32 @test_varargs(i32 %count, ...) {
; CHECK-LABEL: test_varargs:
entry:
  %ap = alloca ptr, align 4
  call void @llvm.va_start(ptr %ap)
  call void @llvm.va_end(ptr %ap)
  ret i32 %count
}

;-----------------------------------------------------------------------------
; Callee-saved registers - r20-r29, EP, LP should be preserved
;-----------------------------------------------------------------------------

declare void @external_func()

define i32 @test_callee_saved(i32 %x) {
; CHECK-LABEL: test_callee_saved:
; CHECK:       prepare
; Uses callee-saved to hold value across call
; CHECK:       mov r6, r20
; CHECK:       jarl external_func, r31
; CHECK:       mov r20, r10
; CHECK:       dispose
  call void @external_func()
  ret i32 %x
}
