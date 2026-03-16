; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m -mattr=+v850fpu < %s | FileCheck %s

; Test that double-precision FP comparisons use CMPF.D + TRFSR + CMOV.

; CHECK-LABEL: test_dcmp_eq:
; CHECK:       cmpf.d {{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}, 0
; CHECK:       trfsr 0
; CHECK:       jmp [r31]
define i1 @test_dcmp_eq(double %a, double %b) {
  %r = fcmp oeq double %a, %b
  ret i1 %r
}

; CHECK-LABEL: test_dcmp_lt:
; CHECK:       cmpf.d
; CHECK:       trfsr
; CHECK:       jmp [r31]
define i1 @test_dcmp_lt(double %a, double %b) {
  %r = fcmp olt double %a, %b
  ret i1 %r
}

; CHECK-LABEL: test_dcmp_le:
; CHECK:       cmpf.d
; CHECK:       trfsr
; CHECK:       jmp [r31]
define i1 @test_dcmp_le(double %a, double %b) {
  %r = fcmp ole double %a, %b
  ret i1 %r
}

; CHECK-LABEL: test_dcmp_ne:
; CHECK:       cmpf.d
; CHECK:       trfsr
; CHECK:       jmp [r31]
define i1 @test_dcmp_ne(double %a, double %b) {
  %r = fcmp une double %a, %b
  ret i1 %r
}

; Test SELECT_CC with f64 result — uses CMOVF.D (single instruction).
; CHECK-LABEL: test_dselect:
; CHECK:       cmpf.d
; CHECK-NEXT:  cmovf.d
; CHECK:       jmp [r31]
define double @test_dselect(double %a, double %b) {
  %cond = fcmp olt double %a, %b
  %r = select i1 %cond, double %a, double %b
  ret double %r
}

; Test dmin using MINF.D.
; CHECK-LABEL: test_dmin:
; CHECK:       minf.d
; CHECK:       jmp [r31]
define double @test_dmin(double %a, double %b) {
  %r = call double @llvm.minnum.f64(double %a, double %b)
  ret double %r
}

; Test dmax using MAXF.D.
; CHECK-LABEL: test_dmax:
; CHECK:       maxf.d
; CHECK:       jmp [r31]
define double @test_dmax(double %a, double %b) {
  %r = call double @llvm.maxnum.f64(double %a, double %b)
  ret double %r
}

declare double @llvm.minnum.f64(double, double)
declare double @llvm.maxnum.f64(double, double)
