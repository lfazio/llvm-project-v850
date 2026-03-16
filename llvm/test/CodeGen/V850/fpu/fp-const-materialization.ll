; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m < %s | FileCheck %s

; Test f32 constant materialization via integer MOV/MOVHI instructions
; instead of loading from constant pool (saves 1-2 instructions per constant).

;===----------------------------------------------------------------------===;
; Zero: 0x00000000 - use MOV r0 (1 insn)
;===----------------------------------------------------------------------===;

; CHECK-LABEL: const_zero:
; CHECK:       mov r0, r10
; CHECK-NEXT:  jmp [r31]
define float @const_zero() {
  ret float 0.0
}

;===----------------------------------------------------------------------===;
; Constants with zero lower 16 bits - use single MOVHI (1 insn)
;===----------------------------------------------------------------------===;

; 1.0f = 0x3F800000 (hi=0x3F80, lo=0x0000)
; CHECK-LABEL: const_one:
; CHECK:       movhi 16256, r0, r10
; CHECK-NEXT:  jmp [r31]
define float @const_one() {
  ret float 1.0
}

; -1.0f = 0xBF800000 (hi=0xBF80, lo=0x0000)
; CHECK-LABEL: const_neg_one:
; CHECK:       movhi 49024, r0, r10
; CHECK-NEXT:  jmp [r31]
define float @const_neg_one() {
  ret float -1.0
}

; 0.5f = 0x3F000000 (hi=0x3F00, lo=0x0000)
; CHECK-LABEL: const_half:
; CHECK:       movhi 16128, r0, r10
; CHECK-NEXT:  jmp [r31]
define float @const_half() {
  ret float 0.5
}

; 2.0f = 0x40000000 (hi=0x4000, lo=0x0000)
; CHECK-LABEL: const_two:
; CHECK:       movhi 16384, r0, r10
; CHECK-NEXT:  jmp [r31]
define float @const_two() {
  ret float 2.0
}

; -0.0f = 0x80000000 (hi=0x8000, lo=0x0000)
; CHECK-LABEL: const_neg_zero:
; CHECK:       movhi 32768, r0, r10
; CHECK-NEXT:  jmp [r31]
define float @const_neg_zero() {
  ret float -0.0
}

;===----------------------------------------------------------------------===;
; Non-trivial bit pattern - use MOV imm32 (1.5 insn, 48-bit, V850E1+)
;===----------------------------------------------------------------------===;

; pi = 0x40490FDB
; CHECK-LABEL: const_pi:
; CHECK:       mov 1078530011, r10
; CHECK-NEXT:  jmp [r31]
define float @const_pi() {
  ret float 0x400921FB60000000
}

;===----------------------------------------------------------------------===;
; Use in arithmetic - constant materialized inline, no const pool
;===----------------------------------------------------------------------===;

; CHECK-LABEL: add_const:
; CHECK:       movhi 16256, r0, r{{[0-9]+}}
; CHECK:       addf.s r{{[0-9]+}}, r6, r10
; CHECK:       jmp [r31]
define float @add_const(float %x) {
  %r = fadd float %x, 1.0
  ret float %r
}

; CHECK-LABEL: mul_const:
; CHECK:       movhi 16128, r0, r{{[0-9]+}}
; CHECK:       mulf.s r{{[0-9]+}}, r6, r10
; CHECK:       jmp [r31]
define float @mul_const(float %x) {
  %r = fmul float %x, 0.5
  ret float %r
}
