; RUN: llc -march=v850 -mcpu=v850e2m -O0 < %s | FileCheck %s

; Test FPU arithmetic operations with native instruction selection

; CHECK-LABEL: test_fadd:
; CHECK: addf.s
define float @test_fadd(float %a, float %b) {
  %c = fadd float %a, %b
  ret float %c
}

; CHECK-LABEL: test_fsub:
; CHECK: subf.s
define float @test_fsub(float %a, float %b) {
  %c = fsub float %a, %b
  ret float %c
}

; CHECK-LABEL: test_fmul:
; CHECK: mulf.s
define float @test_fmul(float %a, float %b) {
  %c = fmul float %a, %b
  ret float %c
}

; CHECK-LABEL: test_fdiv:
; CHECK: divf.s
define float @test_fdiv(float %a, float %b) {
  %c = fdiv float %a, %b
  ret float %c
}

; CHECK-LABEL: test_fabs:
; CHECK: absf.s
define float @test_fabs(float %a) {
  %c = call float @llvm.fabs.f32(float %a)
  ret float %c
}

; CHECK-LABEL: test_fneg:
; CHECK: negf.s
define float @test_fneg(float %a) {
  %c = fneg float %a
  ret float %c
}

; CHECK-LABEL: test_fsqrt:
; CHECK: sqrtf.s
define float @test_fsqrt(float %a) {
  %c = call float @llvm.sqrt.f32(float %a)
  ret float %c
}

; CHECK-LABEL: test_fmaxnum:
; CHECK: maxf.s
define float @test_fmaxnum(float %a, float %b) {
  %c = call float @llvm.maxnum.f32(float %a, float %b)
  ret float %c
}

; CHECK-LABEL: test_fminnum:
; CHECK: minf.s
define float @test_fminnum(float %a, float %b) {
  %c = call float @llvm.minnum.f32(float %a, float %b)
  ret float %c
}

declare float @llvm.fabs.f32(float)
declare float @llvm.sqrt.f32(float)
declare float @llvm.maxnum.f32(float, float)
declare float @llvm.minnum.f32(float, float)
