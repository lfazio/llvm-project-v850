; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m -mattr=+v850fpu < %s | FileCheck %s

; Test that double-precision FPU operations use hardware instructions.

; CHECK-LABEL: test_fadd_d:
; CHECK:       addf.d
; CHECK:       jmp [r31]
define double @test_fadd_d(double %a, double %b) {
  %r = fadd double %a, %b
  ret double %r
}

; CHECK-LABEL: test_fsub_d:
; CHECK:       subf.d
; CHECK:       jmp [r31]
define double @test_fsub_d(double %a, double %b) {
  %r = fsub double %a, %b
  ret double %r
}

; CHECK-LABEL: test_fmul_d:
; CHECK:       mulf.d
; CHECK:       jmp [r31]
define double @test_fmul_d(double %a, double %b) {
  %r = fmul double %a, %b
  ret double %r
}

; CHECK-LABEL: test_fdiv_d:
; CHECK:       divf.d
; CHECK:       jmp [r31]
define double @test_fdiv_d(double %a, double %b) {
  %r = fdiv double %a, %b
  ret double %r
}

; CHECK-LABEL: test_fabs_d:
; CHECK:       absf.d
; CHECK:       jmp [r31]
define double @test_fabs_d(double %a) {
  %r = call double @llvm.fabs.f64(double %a)
  ret double %r
}

; CHECK-LABEL: test_fneg_d:
; CHECK:       negf.d
; CHECK:       jmp [r31]
define double @test_fneg_d(double %a) {
  %r = fneg double %a
  ret double %r
}

; CHECK-LABEL: test_fsqrt_d:
; CHECK:       sqrtf.d
; CHECK:       jmp [r31]
define double @test_fsqrt_d(double %a) {
  %r = call double @llvm.sqrt.f64(double %a)
  ret double %r
}

; CHECK-LABEL: test_fmaxnum_d:
; CHECK:       maxf.d
; CHECK:       jmp [r31]
define double @test_fmaxnum_d(double %a, double %b) {
  %r = call double @llvm.maxnum.f64(double %a, double %b)
  ret double %r
}

; CHECK-LABEL: test_fminnum_d:
; CHECK:       minf.d
; CHECK:       jmp [r31]
define double @test_fminnum_d(double %a, double %b) {
  %r = call double @llvm.minnum.f64(double %a, double %b)
  ret double %r
}

declare double @llvm.fabs.f64(double)
declare double @llvm.sqrt.f64(double)
declare double @llvm.maxnum.f64(double, double)
declare double @llvm.minnum.f64(double, double)
