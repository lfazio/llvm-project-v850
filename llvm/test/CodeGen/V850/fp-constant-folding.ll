; RUN: llc -mtriple=v850 -mcpu=v850e2m < %s | FileCheck %s

; Test floating-point constant folding.
; LLVM middle-end and DAGCombiner handle most FP constant folding with proper
; IEEE 754 compliance.

;; Pure constant operations - folded at compile time

; CHECK-LABEL: test_const_add:
; CHECK-NOT: addf.s
; CHECK: movhi
; CHECK: movea
; CHECK: ld.w
; CHECK-NEXT: jmp [r31]
define float @test_const_add() {
  ; 1.0 + 2.0 = 3.0 - folded to constant
  %result = fadd float 1.0, 2.0
  ret float %result
}

; CHECK-LABEL: test_const_mul:
; CHECK-NOT: mulf.s
; CHECK: movhi
; CHECK: movea
; CHECK: ld.w
; CHECK-NEXT: jmp [r31]
define float @test_const_mul() {
  ; 2.0 * 3.0 = 6.0 - folded to constant
  %result = fmul float 2.0, 3.0
  ret float %result
}

; CHECK-LABEL: test_const_fma:
; CHECK-NOT: maddf.s
; CHECK: movhi
; CHECK: movea
; CHECK: ld.w
; CHECK-NEXT: jmp [r31]
define float @test_const_fma() {
  ; fma(2.0, 3.0, 1.0) = 7.0 - folded to constant
  %result = call float @llvm.fma.f32(float 2.0, float 3.0, float 1.0)
  ret float %result
}

;; Identity operations

; fmul x, 1.0 is always identity (IEEE 754 compliant)
; CHECK-LABEL: test_mul_by_1:
; CHECK: mov r6, r10
; CHECK-NEXT: jmp [r31]
define float @test_mul_by_1(float %x) {
  %result = fmul float %x, 1.0
  ret float %result
}

; fadd x, -0.0 is always identity (adding negative zero preserves sign)
; CHECK-LABEL: test_add_neg_zero:
; CHECK: mov r6, r10
; CHECK-NEXT: jmp [r31]
define float @test_add_neg_zero(float %x) {
  %result = fadd float %x, -0.0
  ret float %result
}

; fadd x, 0.0 with nsz flag can be optimized to identity
; CHECK-LABEL: test_add_zero_nsz:
; CHECK: mov r6, r10
; CHECK-NEXT: jmp [r31]
define float @test_add_zero_nsz(float %x) {
  %result = fadd nsz float %x, 0.0
  ret float %result
}

; fsub x, 0.0 with nsz flag can be optimized to identity
; CHECK-LABEL: test_sub_zero_nsz:
; CHECK: mov r6, r10
; CHECK-NEXT: jmp [r31]
define float @test_sub_zero_nsz(float %x) {
  %result = fsub nsz float %x, 0.0
  ret float %result
}

;; Strength reduction

; fmul x, 2.0 is optimized to addf.s x, x
; CHECK-LABEL: test_mul_by_2:
; CHECK: addf.s r6, r6, r10
; CHECK-NEXT: jmp [r31]
define float @test_mul_by_2(float %x) {
  %result = fmul float %x, 2.0
  ret float %result
}

;; IEEE 754 correctness - these must NOT be optimized

; fadd x, 0.0 without fast-math flags must keep the operation
; because -0.0 + 0.0 = +0.0 (sign changes!)
; CHECK-LABEL: test_add_zero_strict:
; CHECK: addf.s
; CHECK: jmp [r31]
define float @test_add_zero_strict(float %x) {
  %result = fadd float %x, 0.0
  ret float %result
}

declare float @llvm.fma.f32(float, float, float)
