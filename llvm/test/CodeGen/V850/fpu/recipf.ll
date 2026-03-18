; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m < %s | FileCheck %s

; Test that fdiv 1.0, x is lowered to RECIPF.S/D instead of materializing
; the constant 1.0 and using DIVF. RECIPF is IEEE-compliant and faster:
; RECIPF.S: 10 cycles vs DIVF.S: 14 cycles
; RECIPF.D: 22 cycles vs DIVF.D: 62 cycles

; CHECK-LABEL: recipf_f32:
; CHECK:       recipf.s r{{[0-9]+}}, r10
; CHECK-NEXT:  jmp [r31]
define float @recipf_f32(float %x) {
  %r = fdiv float 1.0, %x
  ret float %r
}

; CHECK-LABEL: recipf_f64:
; CHECK:       recipf.d r{{[0-9]+}}, r10
; CHECK-NEXT:  jmp [r31]
define double @recipf_f64(double %x) {
  %r = fdiv double 1.0, %x
  ret double %r
}

; Regular division should still use DIVF
; CHECK-LABEL: divf_f32:
; CHECK:       divf.s r{{[0-9]+}}, r{{[0-9]+}}, r10
; CHECK-NEXT:  jmp [r31]
define float @divf_f32(float %x, float %y) {
  %r = fdiv float %x, %y
  ret float %r
}

; CHECK-LABEL: divf_f64:
; CHECK:       divf.d r{{[0-9]+}}, r{{[0-9]+}}, r10
; CHECK-NEXT:  jmp [r31]
define double @divf_f64(double %x, double %y) {
  %r = fdiv double %x, %y
  ret double %r
}

; Division by constant other than 1.0 should use DIVF, not RECIPF
; CHECK-LABEL: divby2_f32:
; CHECK-NOT:   recipf.s
; CHECK:       divf.s
define float @divby2_f32(float %x) {
  %r = fdiv float 2.0, %x
  ret float %r
}
