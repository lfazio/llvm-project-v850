; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m < %s | FileCheck %s

; Test CFI (Call Frame Information) directive emission for V850.
; CFI directives enable stack unwinding for debuggers and exception handling.
;
; The initial frame state is configured in V850MCTargetDesc.cpp:
;   CFA = SP + 0 (DW_CFA_def_cfa r3, 0)
; This means at function entry, the CFA (Canonical Frame Address) equals the
; stack pointer value.

;; Test 1: Simple function with no stack frame
; No CFI directives needed beyond .cfi_startproc/.cfi_endproc
; CHECK-LABEL: simple_func:
; CHECK:       .cfi_startproc
; CHECK-NOT:   .cfi_def_cfa_offset
; CHECK-NOT:   .cfi_offset
; CHECK:       add r7, r6
; CHECK:       jmp [r31]
; CHECK:       .cfi_endproc
define i32 @simple_func(i32 %a, i32 %b) {
  %sum = add i32 %a, %b
  ret i32 %sum
}

;; Test 2: Function with call (needs to save LP)
; PREPARE saves LP, then stack is allocated for locals
; CHECK-LABEL: func_with_call:
; CHECK:       .cfi_startproc
; CHECK:       prepare 2048, 0
; CHECK-NEXT:  .cfi_def_cfa_offset 4
; CHECK-NEXT:  .cfi_offset r31, -4
; CHECK:       add -4, r3
; CHECK-NEXT:  .cfi_def_cfa_offset 8
; CHECK:       jarl external_func, lp
; CHECK:       dispose 0, 2048, [r31]
; CHECK:       .cfi_endproc
define i32 @func_with_call(i32 %a) {
  %result = call i32 @external_func(i32 %a)
  ret i32 %result
}

declare i32 @external_func(i32)

;; Test 3: Function with local variables but no call
; Stack allocation for locals, no callee-saved registers
; CHECK-LABEL: func_with_locals:
; CHECK:       .cfi_startproc
; CHECK:       addi -40, r3, r3
; CHECK-NEXT:  .cfi_def_cfa_offset 40
; CHECK:       jmp [r31]
; CHECK:       .cfi_endproc
define i32 @func_with_locals(i32 %a, i32 %b) {
  %arr = alloca [10 x i32], align 4
  %ptr = getelementptr [10 x i32], ptr %arr, i32 0, i32 0
  store i32 %a, ptr %ptr, align 4
  %result = add i32 %a, %b
  ret i32 %result
}

;; Test 4: Function with multiple callee-saved registers
; CHECK-LABEL: func_multi_csr:
; CHECK:       .cfi_startproc
; CHECK:       prepare {{[0-9]+}}, 0
; CHECK-NEXT:  .cfi_def_cfa_offset {{[0-9]+}}
; CHECK:       .cfi_offset
; CHECK:       .cfi_endproc
define i32 @func_multi_csr(i32 %a) {
entry:
  %call1 = call i32 @external_func(i32 %a)
  %call2 = call i32 @external_func(i32 %call1)
  %call3 = call i32 @external_func(i32 %call2)
  ret i32 %call3
}

;; Test 5: Function with frame pointer
; When FP is used, CFA should be defined relative to FP
; CHECK-LABEL: func_with_fp:
; CHECK:       .cfi_startproc
; CHECK:       .cfi_def_cfa_offset
; CHECK:       .cfi_endproc
define i32 @func_with_fp(i32 %n) "frame-pointer"="all" {
entry:
  %vla = alloca i32, i32 %n, align 4
  store i32 42, ptr %vla, align 4
  %val = load i32, ptr %vla, align 4
  ret i32 %val
}
