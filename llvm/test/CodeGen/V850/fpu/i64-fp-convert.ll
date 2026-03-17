; RUN: llc -mtriple=v850 -mcpu=v850e2m -O2 < %s | FileCheck %s

; Test hardware i64 <-> FP conversion instructions.
; V850E2M FPU provides: CVTF.LS/LD/ULS/ULD and TRNCF.SL/DL/SUL/DUL.
; These eliminate library calls (__floatdisf, __fixsfdi, etc.)

;--- i64 -> f32 conversions ---

; CHECK-LABEL: si64_to_f32:
; CHECK:         cvtf.ls d6, r10
; CHECK-NEXT:    jmp [r31]
define float @si64_to_f32(i64 %x) {
  %r = sitofp i64 %x to float
  ret float %r
}

; CHECK-LABEL: ui64_to_f32:
; CHECK:         cvtf.uls d6, r10
; CHECK-NEXT:    jmp [r31]
define float @ui64_to_f32(i64 %x) {
  %r = uitofp i64 %x to float
  ret float %r
}

;--- i64 -> f64 conversions ---

; CHECK-LABEL: si64_to_f64:
; CHECK:         cvtf.ld d6, r10
; CHECK-NEXT:    jmp [r31]
define double @si64_to_f64(i64 %x) {
  %r = sitofp i64 %x to double
  ret double %r
}

; CHECK-LABEL: ui64_to_f64:
; CHECK:         cvtf.uld d6, r10
; CHECK-NEXT:    jmp [r31]
define double @ui64_to_f64(i64 %x) {
  %r = uitofp i64 %x to double
  ret double %r
}

;--- f32 -> i64 conversions ---

; CHECK-LABEL: f32_to_si64:
; CHECK:         trncf.sl r6, d10
; CHECK-NEXT:    jmp [r31]
define i64 @f32_to_si64(float %x) {
  %r = fptosi float %x to i64
  ret i64 %r
}

; CHECK-LABEL: f32_to_ui64:
; CHECK:         trncf.sul r6, d10
; CHECK-NEXT:    jmp [r31]
define i64 @f32_to_ui64(float %x) {
  %r = fptoui float %x to i64
  ret i64 %r
}

;--- f64 -> i64 conversions ---

; CHECK-LABEL: f64_to_si64:
; CHECK:         trncf.dl r6, d10
; CHECK-NEXT:    jmp [r31]
define i64 @f64_to_si64(double %x) {
  %r = fptosi double %x to i64
  ret i64 %r
}

; CHECK-LABEL: f64_to_ui64:
; CHECK:         trncf.dul r6, d10
; CHECK-NEXT:    jmp [r31]
define i64 @f64_to_ui64(double %x) {
  %r = fptoui double %x to i64
  ret i64 %r
}
