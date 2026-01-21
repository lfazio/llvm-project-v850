; RUN: llc -march=v850 -mcpu=v850e2m -O2 < %s | FileCheck %s

; Test V850 peephole optimizations.

; Test 1: Zero-extending byte load should not have redundant ANDI 0xFF
; The LDBU instruction already zero-extends, so ANDI 0xFF should be removed.
define i32 @load_zext_byte(ptr %p) {
; CHECK-LABEL: load_zext_byte:
; CHECK:       ld.bu 0[r6], r10
; CHECK-NOT:   andi 255
; CHECK:       jmp [r31]
entry:
  %val = load i8, ptr %p
  %ext = zext i8 %val to i32
  ret i32 %ext
}

; Test 2: Zero-extending halfword load should not have redundant ANDI 0xFFFF
; The LDHU instruction already zero-extends, so ANDI 0xFFFF should be removed.
define i32 @load_zext_halfword(ptr %p) {
; CHECK-LABEL: load_zext_halfword:
; CHECK:       ld.hu 0[r6], r10
; CHECK-NOT:   andi 65535
; CHECK:       jmp [r31]
entry:
  %val = load i16, ptr %p
  %ext = zext i16 %val to i32
  ret i32 %ext
}

; Test 3: Sign-extending loads should still work correctly (no peephole)
define i32 @load_sext_byte(ptr %p) {
; CHECK-LABEL: load_sext_byte:
; CHECK:       ld.b 0[r6], r10
; CHECK:       jmp [r31]
entry:
  %val = load i8, ptr %p
  %ext = sext i8 %val to i32
  ret i32 %ext
}

; Test 4: Sign-extending halfword load
define i32 @load_sext_halfword(ptr %p) {
; CHECK-LABEL: load_sext_halfword:
; CHECK:       ld.h 0[r6], r10
; CHECK:       jmp [r31]
entry:
  %val = load i16, ptr %p
  %ext = sext i16 %val to i32
  ret i32 %ext
}

; Test 5: ANDI with non-mask value should not be removed
define i32 @load_and_mask(ptr %p) {
; CHECK-LABEL: load_and_mask:
; CHECK:       ld.bu 0[r6], r{{[0-9]+}}
; CHECK:       andi 127, r{{[0-9]+}}, r10
; CHECK:       jmp [r31]
entry:
  %val = load i8, ptr %p
  %ext = zext i8 %val to i32
  %masked = and i32 %ext, 127
  ret i32 %masked
}

; Test 6: Small constant load should use mov immediate efficiently
; Loading zero and adding a small constant should fold to mov immediate
define i32 @small_constant() {
; CHECK-LABEL: small_constant:
; CHECK:       mov 5, r10
; CHECK:       jmp [r31]
entry:
  ret i32 5
}

; Test 7: Negative small constant
define i32 @small_negative_constant() {
; CHECK-LABEL: small_negative_constant:
; CHECK:       mov -3, r10
; CHECK:       jmp [r31]
entry:
  ret i32 -3
}

; Test 8: Large constant should use movea or movhi
define i32 @large_constant() {
; CHECK-LABEL: large_constant:
; CHECK:       movea 12345, r0, r10
; CHECK:       jmp [r31]
entry:
  ret i32 12345
}
