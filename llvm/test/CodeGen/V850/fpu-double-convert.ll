; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m -mattr=+v850fpu < %s | FileCheck %s

; Test double-precision FPU conversion instructions.

; CHECK-LABEL: test_fpextend:
; CHECK:       cvtf.sd
; CHECK:       jmp [r31]
define double @test_fpextend(float %a) {
  %r = fpext float %a to double
  ret double %r
}

; CHECK-LABEL: test_fpround:
; CHECK:       cvtf.ds
; CHECK:       jmp [r31]
define float @test_fpround(double %a) {
  %r = fptrunc double %a to float
  ret float %r
}

; CHECK-LABEL: test_fp_to_sint_d:
; CHECK:       trncf.dw
; CHECK:       jmp [r31]
define i32 @test_fp_to_sint_d(double %a) {
  %r = fptosi double %a to i32
  ret i32 %r
}

; CHECK-LABEL: test_fp_to_uint_d:
; CHECK:       trncf.duw
; CHECK:       jmp [r31]
define i32 @test_fp_to_uint_d(double %a) {
  %r = fptoui double %a to i32
  ret i32 %r
}

; CHECK-LABEL: test_sint_to_fp_d:
; CHECK:       cvtf.wd
; CHECK:       jmp [r31]
define double @test_sint_to_fp_d(i32 %a) {
  %r = sitofp i32 %a to double
  ret double %r
}

; CHECK-LABEL: test_uint_to_fp_d:
; CHECK:       cvtf.uwd
; CHECK:       jmp [r31]
define double @test_uint_to_fp_d(i32 %a) {
  %r = uitofp i32 %a to double
  ret double %r
}
