; RUN: llc -mtriple=v850 -mcpu=v850e2m -frame-pointer=all < %s | FileCheck %s --check-prefix=CHECK-FP
; RUN: llc -mtriple=v850 -mcpu=v850e2m -frame-pointer=none < %s | FileCheck %s --check-prefix=CHECK-NO-FP

;===----------------------------------------------------------------------===;
; Test frame pointer chain implementation
;
; When frame pointer is enabled, FP (r29) should point to where the old FP
; was saved, enabling debuggers to walk the stack by following the chain:
;   [FP] = previous frame's FP
;===----------------------------------------------------------------------===;

;===----------------------------------------------------------------------===;
; Test 1: Basic function with frame pointer
;
; With frame pointer enabled:
; - FP should point to the saved old FP location
; - [FP] = old FP (frame chain)
; - CFI should correctly describe the frame layout
;===----------------------------------------------------------------------===;

; CHECK-FP-LABEL: test_frame_chain:
; CHECK-FP:       .cfi_def_cfa_offset
; CHECK-FP:       addi {{[0-9]+}}, r3, r29
; CHECK-FP:       .cfi_def_cfa r29,
; Stack frame stores old FP at [FP + 0] for proper frame chain
; CHECK-FP:       st.w r29, 0[r29]
; CHECK-FP:       .cfi_offset r29,

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
; CHECK-FP:       addi {{[0-9]+}}, r3, r29
; CHECK-FP:       st.w r29, 0[r29]
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
; should still be correct.
;===----------------------------------------------------------------------===;

; CHECK-FP-LABEL: test_variable_alloca:
; Frame pointer is required for variable alloca
; CHECK-FP:       addi {{[0-9]+}}, r3, r29
; CHECK-FP:       st.w r29, 0[r29]
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
; CHECK-FP:       addi {{[0-9]+}}, r3, r29
; CHECK-FP:       st.w r29, 0[r29]
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
; SP should be correctly restored from FP in the epilogue.
;===----------------------------------------------------------------------===;

; CHECK-FP-LABEL: test_epilogue_restore:
; Prologue: FP = SP + offset
; CHECK-FP:       addi {{[0-9]+}}, r3, r29
; Epilogue: SP = FP - offset (inverse of prologue)
; CHECK-FP:       addi {{-[0-9]+}}, r29, r3
; CHECK-FP:       jmp [r31]
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
