; RUN: llc -mtriple=v850 -mcpu=v850e2m -frame-pointer=all < %s | FileCheck %s --check-prefix=CHECK-FP
; RUN: llc -mtriple=v850 -mcpu=v850e2m -frame-pointer=none < %s | FileCheck %s --check-prefix=CHECK-NO-FP

;===----------------------------------------------------------------------===;
; Test frame pointer chain implementation
;
; When frame pointer is enabled, FP (r29) should point to where the old FP
; was saved, enabling debuggers to walk the stack by following the chain:
;   [FP] = previous frame's FP
;
; With PREPARE/DISPOSE enabled for FP functions, the old r29 is saved by
; PREPARE and FP is set up via ADDI to point to the saved location.
;===----------------------------------------------------------------------===;

;===----------------------------------------------------------------------===;
; Test 1: Basic function with frame pointer
;
; PREPARE saves LP, r29, and other CSRs. FP is set up to point to saved r29.
;===----------------------------------------------------------------------===;

; CHECK-FP-LABEL: test_frame_chain:
; CHECK-FP:       prepare
; CHECK-FP:       .cfi_def_cfa_offset
; CHECK-FP:       .cfi_offset r31,
; CHECK-FP:       .cfi_offset r29,
; CHECK-FP:       addi {{[0-9]+}}, r3, r29
; CHECK-FP:       .cfi_def_cfa r29,

; Without frame pointer, uses PREPARE instruction and no FP setup
; CHECK-NO-FP-LABEL: test_frame_chain:
; CHECK-NO-FP:       prepare
define i32 @test_frame_chain(i32 %a) {
entry:
  %local = alloca i32
  store i32 %a, ptr %local
  call void @external()
  %v = load i32, ptr %local
  ret i32 %v
}

;===----------------------------------------------------------------------===;
; Test 2: Nested function calls with frame pointer
;
; Each function should maintain proper frame chain so debugger can
; walk through: current_FP -> previous_FP -> grandparent_FP -> ...
;===----------------------------------------------------------------------===;

; CHECK-FP-LABEL: test_nested_calls:
; CHECK-FP:       prepare
; CHECK-FP:       addi {{[0-9]+}}, r3, r29
; CHECK-FP:       .cfi_def_cfa r29,
define i32 @test_nested_calls(i32 %a, i32 %b) {
entry:
  %local1 = alloca i32
  %local2 = alloca i32
  store i32 %a, ptr %local1
  store i32 %b, ptr %local2
  call void @external()
  %v1 = load i32, ptr %local1
  %v2 = load i32, ptr %local2
  %sum = add i32 %v1, %v2
  call void @external()
  ret i32 %sum
}

;===----------------------------------------------------------------------===;
; Test 3: Variable-sized stack allocation (alloca with variable size)
;
; Variable-sized allocations require frame pointer, and the frame chain
; should still be correct. StackSize == 0 with block CSR save.
;===----------------------------------------------------------------------===;

; CHECK-FP-LABEL: test_variable_alloca:
; CHECK-FP:       prepare
; CHECK-FP:       addi {{[0-9]+}}, r3, r29
; CHECK-FP:       .cfi_def_cfa r29,
define i32 @test_variable_alloca(i32 %n) {
entry:
  %vla = alloca i32, i32 %n
  %ptr = getelementptr i32, ptr %vla, i32 0
  store i32 42, ptr %ptr
  call void @external()
  %v = load i32, ptr %ptr
  ret i32 %v
}

;===----------------------------------------------------------------------===;
; Test 4: Function with many local variables
;
; Even with larger stack frames, frame chain should work correctly.
;===----------------------------------------------------------------------===;

; CHECK-FP-LABEL: test_large_frame:
; CHECK-FP:       prepare
; CHECK-FP:       addi {{[0-9]+}}, r3, r29
; CHECK-FP:       .cfi_def_cfa r29,
define i32 @test_large_frame(i32 %a) {
entry:
  %local1 = alloca [100 x i32]
  %local2 = alloca [100 x i32]
  %ptr1 = getelementptr [100 x i32], ptr %local1, i32 0, i32 0
  %ptr2 = getelementptr [100 x i32], ptr %local2, i32 0, i32 0
  store i32 %a, ptr %ptr1
  store i32 %a, ptr %ptr2
  call void @external()
  %v1 = load i32, ptr %ptr1
  %v2 = load i32, ptr %ptr2
  %sum = add i32 %v1, %v2
  ret i32 %sum
}

;===----------------------------------------------------------------------===;
; Test 5: Epilogue correctly restores SP from FP
;
; SP should be correctly restored from FP in the epilogue before DISPOSE.
;===----------------------------------------------------------------------===;

; CHECK-FP-LABEL: test_epilogue_restore:
; Prologue: FP = SP + offset
; CHECK-FP:       prepare
; CHECK-FP:       addi {{[0-9]+}}, r3, r29
; Epilogue: SP = FP - offset (inverse of prologue), then DISPOSE
; CHECK-FP:       addi {{-[0-9]+}}, r29, r3
; CHECK-FP:       dispose
define i32 @test_epilogue_restore(i32 %a, i32 %b) {
entry:
  %local = alloca i32
  store i32 %a, ptr %local
  call void @external()
  %v = load i32, ptr %local
  %result = add i32 %v, %b
  ret i32 %result
}

declare void @external()
