; RUN: llc -mtriple=v850 -O2 < %s | FileCheck %s --check-prefix=V850
; RUN: llc -mtriple=v850 -mcpu=v850e1 -O2 < %s | FileCheck %s --check-prefix=V850E1

; Test sign/zero extension patterns
; V850E1+ has SXB, SXH, ZXB, ZXH instructions for in-register extension
; V850E1+ has LD.BU, LD.HU for zero-extending loads
; Base V850 must use shifts for sign extension, ANDI for zero extension

;============================================================================
; Sign Extension in Register
;============================================================================

; V850-LABEL: sext_byte:
; V850:       shl 24, r6
; V850:       sar 24, r6
; V850E1-LABEL: sext_byte:
; V850E1:     sxb r6
define i32 @sext_byte(i32 %a) {
  %trunc = trunc i32 %a to i8
  %ext = sext i8 %trunc to i32
  ret i32 %ext
}

; V850-LABEL: sext_half:
; V850:       shl 16, r6
; V850:       sar 16, r6
; V850E1-LABEL: sext_half:
; V850E1:     sxh r6
define i32 @sext_half(i32 %a) {
  %trunc = trunc i32 %a to i16
  %ext = sext i16 %trunc to i32
  ret i32 %ext
}

;============================================================================
; Zero Extension in Register
;============================================================================

; V850-LABEL: zext_byte:
; V850:       andi 255, r6, r10
; V850E1-LABEL: zext_byte:
; V850E1:     zxb r6
define i32 @zext_byte(i32 %a) {
  %and = and i32 %a, 255
  ret i32 %and
}

; V850-LABEL: zext_half:
; V850:       andi 65535, r6, r10
; V850E1-LABEL: zext_half:
; V850E1:     zxh r6
define i32 @zext_half(i32 %a) {
  %and = and i32 %a, 65535
  ret i32 %and
}

;============================================================================
; Sign-Extending Loads
;============================================================================

; V850-LABEL: sextload_byte:
; V850:       ld.b 0[r6], r10
; V850E1-LABEL: sextload_byte:
; V850E1:     ld.b 0[r6], r10
define i32 @sextload_byte(ptr %p) {
  %val = load i8, ptr %p
  %ext = sext i8 %val to i32
  ret i32 %ext
}

; V850-LABEL: sextload_half:
; V850:       ld.h 0[r6], r10
; V850E1-LABEL: sextload_half:
; V850E1:     ld.h 0[r6], r10
define i32 @sextload_half(ptr %p) {
  %val = load i16, ptr %p
  %ext = sext i16 %val to i32
  ret i32 %ext
}

;============================================================================
; Zero-Extending Loads
;============================================================================

; V850-LABEL: zextload_byte:
; V850:       ld.b 0[r6], r10
; V850:       andi 255, r10, r10
; V850E1-LABEL: zextload_byte:
; V850E1:     ld.bu 0[r6], r10
define i32 @zextload_byte(ptr %p) {
  %val = load i8, ptr %p
  %ext = zext i8 %val to i32
  ret i32 %ext
}

; V850-LABEL: zextload_half:
; V850:       ld.h 0[r6], r10
; V850:       andi 65535, r10, r10
; V850E1-LABEL: zextload_half:
; V850E1:     ld.hu 0[r6], r10
define i32 @zextload_half(ptr %p) {
  %val = load i16, ptr %p
  %ext = zext i16 %val to i32
  ret i32 %ext
}

;============================================================================
; Loads with Offset
;============================================================================

; V850-LABEL: sextload_byte_offset:
; V850:       ld.b 10[r6], r10
; V850E1-LABEL: sextload_byte_offset:
; V850E1:     ld.b 10[r6], r10
define i32 @sextload_byte_offset(ptr %p) {
  %ptr = getelementptr i8, ptr %p, i32 10
  %val = load i8, ptr %ptr
  %ext = sext i8 %val to i32
  ret i32 %ext
}

; V850-LABEL: zextload_byte_offset:
; V850:       ld.b 10[r6], r10
; V850:       andi 255, r10, r10
; V850E1-LABEL: zextload_byte_offset:
; V850E1:     ld.bu 10[r6], r10
define i32 @zextload_byte_offset(ptr %p) {
  %ptr = getelementptr i8, ptr %p, i32 10
  %val = load i8, ptr %ptr
  %ext = zext i8 %val to i32
  ret i32 %ext
}

; V850-LABEL: sextload_half_offset:
; V850:       ld.h 20[r6], r10
; V850E1-LABEL: sextload_half_offset:
; V850E1:     ld.h 20[r6], r10
define i32 @sextload_half_offset(ptr %p) {
  %ptr = getelementptr i16, ptr %p, i32 10
  %val = load i16, ptr %ptr
  %ext = sext i16 %val to i32
  ret i32 %ext
}

; V850-LABEL: zextload_half_offset:
; V850:       ld.h 20[r6], r10
; V850:       andi 65535, r10, r10
; V850E1-LABEL: zextload_half_offset:
; V850E1:     ld.hu 20[r6], r10
define i32 @zextload_half_offset(ptr %p) {
  %ptr = getelementptr i16, ptr %p, i32 10
  %val = load i16, ptr %ptr
  %ext = zext i16 %val to i32
  ret i32 %ext
}
