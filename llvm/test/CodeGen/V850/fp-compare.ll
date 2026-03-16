; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m < %s | FileCheck %s

;===----------------------------------------------------------------------===;
; Floating-point comparison (SETCC) tests
; V850 FPU uses: CMPF.S fcond, reg1, reg2, fcbit + TRFSR fcbit + SETF z/nz
;===----------------------------------------------------------------------===;

; Ordered comparisons

define i32 @fcmp_oeq(float %a, float %b) {
; CHECK-LABEL: fcmp_oeq:
; CHECK:       cmpf.s 2, r7, r6, 0
; CHECK-NEXT:  trfsr 0
; CHECK-NEXT:  setf z, r10
  %cmp = fcmp oeq float %a, %b
  %r = zext i1 %cmp to i32
  ret i32 %r
}

define i32 @fcmp_ogt(float %a, float %b) {
; CHECK-LABEL: fcmp_ogt:
; CHECK:       cmpf.s 4, r6, r7, 0
; CHECK-NEXT:  trfsr 0
; CHECK-NEXT:  setf z, r10
  %cmp = fcmp ogt float %a, %b
  %r = zext i1 %cmp to i32
  ret i32 %r
}

define i32 @fcmp_oge(float %a, float %b) {
; CHECK-LABEL: fcmp_oge:
; CHECK:       cmpf.s 6, r6, r7, 0
; CHECK-NEXT:  trfsr 0
; CHECK-NEXT:  setf z, r10
  %cmp = fcmp oge float %a, %b
  %r = zext i1 %cmp to i32
  ret i32 %r
}

define i32 @fcmp_olt(float %a, float %b) {
; CHECK-LABEL: fcmp_olt:
; CHECK:       cmpf.s 4, r7, r6, 0
; CHECK-NEXT:  trfsr 0
; CHECK-NEXT:  setf z, r10
  %cmp = fcmp olt float %a, %b
  %r = zext i1 %cmp to i32
  ret i32 %r
}

define i32 @fcmp_ole(float %a, float %b) {
; CHECK-LABEL: fcmp_ole:
; CHECK:       cmpf.s 6, r7, r6, 0
; CHECK-NEXT:  trfsr 0
; CHECK-NEXT:  setf z, r10
  %cmp = fcmp ole float %a, %b
  %r = zext i1 %cmp to i32
  ret i32 %r
}

define i32 @fcmp_one(float %a, float %b) {
; CHECK-LABEL: fcmp_one:
; CHECK:       cmpf.s 3, r7, r6, 0
; CHECK-NEXT:  trfsr 0
; CHECK-NEXT:  setf nz, r10
  %cmp = fcmp one float %a, %b
  %r = zext i1 %cmp to i32
  ret i32 %r
}

define i32 @fcmp_ord(float %a, float %b) {
; CHECK-LABEL: fcmp_ord:
; CHECK:       cmpf.s 1, r7, r6, 0
; CHECK-NEXT:  trfsr 0
; CHECK-NEXT:  setf nz, r10
  %cmp = fcmp ord float %a, %b
  %r = zext i1 %cmp to i32
  ret i32 %r
}

; Unordered comparisons

define i32 @fcmp_uno(float %a, float %b) {
; CHECK-LABEL: fcmp_uno:
; CHECK:       cmpf.s 1, r7, r6, 0
; CHECK-NEXT:  trfsr 0
; CHECK-NEXT:  setf z, r10
  %cmp = fcmp uno float %a, %b
  %r = zext i1 %cmp to i32
  ret i32 %r
}

define i32 @fcmp_ueq(float %a, float %b) {
; CHECK-LABEL: fcmp_ueq:
; CHECK:       cmpf.s 3, r7, r6, 0
; CHECK-NEXT:  trfsr 0
; CHECK-NEXT:  setf z, r10
  %cmp = fcmp ueq float %a, %b
  %r = zext i1 %cmp to i32
  ret i32 %r
}

define i32 @fcmp_ugt(float %a, float %b) {
; CHECK-LABEL: fcmp_ugt:
; CHECK:       cmpf.s 5, r6, r7, 0
; CHECK-NEXT:  trfsr 0
; CHECK-NEXT:  setf z, r10
  %cmp = fcmp ugt float %a, %b
  %r = zext i1 %cmp to i32
  ret i32 %r
}

define i32 @fcmp_uge(float %a, float %b) {
; CHECK-LABEL: fcmp_uge:
; CHECK:       cmpf.s 7, r6, r7, 0
; CHECK-NEXT:  trfsr 0
; CHECK-NEXT:  setf z, r10
  %cmp = fcmp uge float %a, %b
  %r = zext i1 %cmp to i32
  ret i32 %r
}

define i32 @fcmp_ult(float %a, float %b) {
; CHECK-LABEL: fcmp_ult:
; CHECK:       cmpf.s 5, r7, r6, 0
; CHECK-NEXT:  trfsr 0
; CHECK-NEXT:  setf z, r10
  %cmp = fcmp ult float %a, %b
  %r = zext i1 %cmp to i32
  ret i32 %r
}

define i32 @fcmp_ule(float %a, float %b) {
; CHECK-LABEL: fcmp_ule:
; CHECK:       cmpf.s 7, r7, r6, 0
; CHECK-NEXT:  trfsr 0
; CHECK-NEXT:  setf z, r10
  %cmp = fcmp ule float %a, %b
  %r = zext i1 %cmp to i32
  ret i32 %r
}

define i32 @fcmp_une(float %a, float %b) {
; CHECK-LABEL: fcmp_une:
; CHECK:       cmpf.s 2, r7, r6, 0
; CHECK-NEXT:  trfsr 0
; CHECK-NEXT:  setf nz, r10
  %cmp = fcmp une float %a, %b
  %r = zext i1 %cmp to i32
  ret i32 %r
}

;===----------------------------------------------------------------------===;
; Floating-point SELECT_CC tests (CMPF.S + TRFSR + CMOV)
;===----------------------------------------------------------------------===;

; FP comparison with f32 result (uses CMOVF.S instead of TRFSR+CMOV)
define float @fselect_olt(float %a, float %b, float %c, float %d) {
; CHECK-LABEL: fselect_olt:
; CHECK:       cmpf.s 4, r7, r6, 0
; CHECK-NEXT:  cmovf.s 0, r8, r9, r10
  %cmp = fcmp olt float %a, %b
  %r = select i1 %cmp, float %c, float %d
  ret float %r
}

; Integer comparison with f32 result
define float @fselect_int_cmp(i32 %x, float %a, float %b) {
; CHECK-LABEL: fselect_int_cmp:
; CHECK:       cmp 0, r6
; CHECK-NEXT:  cmov gt, r7, r8, r10
  %cmp = icmp sgt i32 %x, 0
  %r = select i1 %cmp, float %a, float %b
  ret float %r
}

; Manual fmin via select (uses CMOVF.S)
define float @fmin_select(float %a, float %b) {
; CHECK-LABEL: fmin_select:
; CHECK:       cmpf.s 4, r7, r6, 0
; CHECK-NEXT:  cmovf.s 0, r6, r7, r10
  %cmp = fcmp olt float %a, %b
  %r = select i1 %cmp, float %a, float %b
  ret float %r
}

; Manual fmax via select (uses CMOVF.S)
define float @fmax_select(float %a, float %b) {
; CHECK-LABEL: fmax_select:
; CHECK:       cmpf.s 4, r6, r7, 0
; CHECK-NEXT:  cmovf.s 0, r6, r7, r10
  %cmp = fcmp ogt float %a, %b
  %r = select i1 %cmp, float %a, float %b
  ret float %r
}

;===----------------------------------------------------------------------===;
; Floating-point BR_CC tests (CMPF.S + TRFSR + BZ/BNZ)
;===----------------------------------------------------------------------===;

define float @fbranch_olt(float %a, float %b, float %c, float %d) {
; CHECK-LABEL: fbranch_olt:
; CHECK:       cmpf.s
; CHECK:       trfsr 0
; CHECK:       b{{z|nz}}
  %cmp = fcmp olt float %a, %b
  br i1 %cmp, label %then, label %else
then:
  ret float %c
else:
  ret float %d
}

;===----------------------------------------------------------------------===;
; Clamp pattern: two FP comparisons chained
;===----------------------------------------------------------------------===;

define float @fclamp(float %x, float %lo, float %hi) {
; CHECK-LABEL: fclamp:
; CHECK:       cmpf.s
; CHECK-NEXT:  cmovf.s
; CHECK:       cmpf.s
; CHECK-NEXT:  cmovf.s
  %cmp_lo = fcmp olt float %x, %lo
  %t1 = select i1 %cmp_lo, float %lo, float %x
  %cmp_hi = fcmp ogt float %t1, %hi
  %t2 = select i1 %cmp_hi, float %hi, float %t1
  ret float %t2
}
