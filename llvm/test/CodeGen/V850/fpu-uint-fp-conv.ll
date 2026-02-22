; RUN: llc -mtriple=v850 -mcpu=v850e2m -verify-machineinstrs < %s | FileCheck %s

; Test unsigned integer ↔ float conversion using CVTF.UWS and TRNCF.SUW.
;
; CVTF.UWS reg2, reg3 — unsigned word to single-precision float
; TRNCF.SUW reg2, reg3 — truncate single-precision float to unsigned word
;                         (truncation toward zero, matches C (unsigned)(float_val))
;
; Previously broken: CVTFUWS had wrong output register class (GPR instead of FPR)
; and missing ISel pattern; TRNCFSUW had wrong input register class (GPR instead of FPR)
; and missing ISel pattern.

; CHECK-LABEL: uint_to_float:
; CHECK:    cvtf.uws r6, r10
; CHECK:    jmp [r31]
define float @uint_to_float(i32 %x) {
  %r = uitofp i32 %x to float
  ret float %r
}

; CHECK-LABEL: float_to_uint:
; CHECK:    trncf.suw r6, r10
; CHECK:    jmp [r31]
define i32 @float_to_uint(float %x) {
  %r = fptoui float %x to i32
  ret i32 %r
}

; CHECK-LABEL: uint_to_float_and_back:
; CHECK:    cvtf.uws r6, r10
; CHECK:    trncf.suw r10, r10
; CHECK:    jmp [r31]
define i32 @uint_to_float_and_back(i32 %x) {
  %f = uitofp i32 %x to float
  %r = fptoui float %f to i32
  ret i32 %r
}

; Signed conversions (CVTF.WS / TRNCF.SW) should still work — regression check.
; CHECK-LABEL: sint_to_float:
; CHECK:    cvtf.ws r6, r10
; CHECK:    jmp [r31]
define float @sint_to_float(i32 %x) {
  %r = sitofp i32 %x to float
  ret float %r
}

; CHECK-LABEL: float_to_sint:
; CHECK:    trncf.sw r6, r10
; CHECK:    jmp [r31]
define i32 @float_to_sint(float %x) {
  %r = fptosi float %x to i32
  ret i32 %r
}
