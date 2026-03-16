; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m -O2 < %s | FileCheck %s

; Test that FPU conditional moves use CMOVF.S/D instead of TRFSR+CMOV

; CHECK-LABEL: test_fmin_f32:
; CHECK:       cmpf.s
; CHECK-NEXT:  cmovf.s
; CHECK-NOT:   trfsr
; CHECK-NOT:   cmov{{[^f]}}
define float @test_fmin_f32(float %a, float %b) {
  %cmp = fcmp olt float %a, %b
  %sel = select i1 %cmp, float %a, float %b
  ret float %sel
}

; CHECK-LABEL: test_fmax_f32:
; CHECK:       cmpf.s
; CHECK-NEXT:  cmovf.s
; CHECK-NOT:   trfsr
define float @test_fmax_f32(float %a, float %b) {
  %cmp = fcmp ogt float %a, %b
  %sel = select i1 %cmp, float %a, float %b
  ret float %sel
}

; CHECK-LABEL: test_fmin_f64:
; CHECK:       cmpf.d
; CHECK-NEXT:  cmovf.d
; CHECK-NOT:   trfsr
; CHECK-NOT:   cmov{{[^f]}}
define double @test_fmin_f64(double %a, double %b) {
  %cmp = fcmp olt double %a, %b
  %sel = select i1 %cmp, double %a, double %b
  ret double %sel
}

; CHECK-LABEL: test_fmax_f64:
; CHECK:       cmpf.d
; CHECK-NEXT:  cmovf.d
; CHECK-NOT:   trfsr
define double @test_fmax_f64(double %a, double %b) {
  %cmp = fcmp ogt double %a, %b
  %sel = select i1 %cmp, double %a, double %b
  ret double %sel
}

; Test ordered equality
; CHECK-LABEL: test_feq_select_f32:
; CHECK:       cmpf.s
; CHECK-NEXT:  cmovf.s
; CHECK-NOT:   trfsr
define float @test_feq_select_f32(float %a, float %b, float %c, float %d) {
  %cmp = fcmp oeq float %a, %b
  %sel = select i1 %cmp, float %c, float %d
  ret float %sel
}

; Test unordered not-equal (NeedNegate case)
; CHECK-LABEL: test_fune_select_f32:
; CHECK:       cmpf.s
; CHECK-NEXT:  cmovf.s
; CHECK-NOT:   trfsr
define float @test_fune_select_f32(float %a, float %b, float %c, float %d) {
  %cmp = fcmp une float %a, %b
  %sel = select i1 %cmp, float %c, float %d
  ret float %sel
}

; Test that LLVM intrinsic fminnum/fmaxnum also benefit
; CHECK-LABEL: test_fminnum_f32:
; CHECK:       minf.s
define float @test_fminnum_f32(float %a, float %b) {
  %r = call float @llvm.minnum.f32(float %a, float %b)
  ret float %r
}

declare float @llvm.minnum.f32(float, float)
