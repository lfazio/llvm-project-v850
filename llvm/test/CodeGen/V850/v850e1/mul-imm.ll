; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m < %s | FileCheck %s

; Test MUL/MULU immediate form instruction selection.
; When a multiply has a small constant operand fitting in simm9 (-256..255),
; use the MULi immediate form instead of loading the constant into a register.

;===----------------------------------------------------------------------===;
; MULi - signed 9-bit immediate multiply
;===----------------------------------------------------------------------===;

; CHECK-LABEL: mul_by_5:
; CHECK:       mul 5, r6, r{{[0-9]+}}
; CHECK:       jmp [r31]
define i32 @mul_by_5(i32 %x) {
  %r = mul i32 %x, 5
  ret i32 %r
}

; CHECK-LABEL: mul_by_neg3:
; CHECK:       mul -3, r6, r{{[0-9]+}}
; CHECK:       jmp [r31]
define i32 @mul_by_neg3(i32 %x) {
  %r = mul i32 %x, -3
  ret i32 %r
}

; CHECK-LABEL: mul_by_255:
; CHECK:       mul 255, r6, r{{[0-9]+}}
; CHECK:       jmp [r31]
define i32 @mul_by_255(i32 %x) {
  %r = mul i32 %x, 255
  ret i32 %r
}

; Large negative that fits in simm9
; CHECK-LABEL: mul_by_neg127:
; CHECK:       mul -127, r6, r{{[0-9]+}}
; CHECK:       jmp [r31]
define i32 @mul_by_neg127(i32 %x) {
  %r = mul i32 %x, -127
  ret i32 %r
}

;===----------------------------------------------------------------------===;
; Constants outside simm9 range - should use register MUL
;===----------------------------------------------------------------------===;

; 256 doesn't fit in simm9 (power-of-2 optimized to shift)
; CHECK-LABEL: mul_by_256:
; CHECK:       shl 8, r6
; CHECK:       jmp [r31]
define i32 @mul_by_256(i32 %x) {
  %r = mul i32 %x, 256
  ret i32 %r
}

; 1000 doesn't fit in simm9, needs register load
; CHECK-LABEL: mul_by_1000:
; CHECK:       movea 1000, r0, r{{[0-9]+}}
; CHECK:       mul r{{[0-9]+}}, r6, r{{[0-9]+}}
define i32 @mul_by_1000(i32 %x) {
  %r = mul i32 %x, 1000
  ret i32 %r
}

;===----------------------------------------------------------------------===;
; MULi in expressions
;===----------------------------------------------------------------------===;

; CHECK-LABEL: mul_add:
; CHECK:       mul 7, r6, r{{[0-9]+}}
; CHECK:       add
define i32 @mul_add(i32 %x) {
  %m = mul i32 %x, 7
  %r = add i32 %m, 42
  ret i32 %r
}
