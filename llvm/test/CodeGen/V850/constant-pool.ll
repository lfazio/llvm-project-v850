; RUN: llc -mtriple=v850 -mcpu=v850e2m < %s | FileCheck %s

; Test floating-point constant materialization.
; V850 materializes f32 constants via integer MOV/MOVHI/MOVEA instructions
; instead of loading from a constant pool, saving 1-2 instructions per constant.

; pi (0x40490FDB) - non-trivial bit pattern, uses MOV imm32 (V850E1+)
; CHECK-LABEL: return_float_const:
; CHECK:       mov 1078530011, r10
; CHECK-NEXT:  jmp [r31]
define float @return_float_const() {
  ret float 0x400921FB60000000  ; approximately pi (3.14159...)
}

; 2.5 (0x40200000) - upper 16 bits only, uses single MOVHI
; CHECK-LABEL: add_float_const:
; CHECK:       movhi 16416, r0, r{{[0-9]+}}
; CHECK:       addf.s r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
; CHECK:       jmp [r31]
define float @add_float_const(float %a) {
  %result = fadd float %a, 0x4004000000000000  ; 2.5
  ret float %result
}

; 0.5 (0x3F000000) - upper 16 bits only, uses single MOVHI
; CHECK-LABEL: mul_float_const:
; CHECK:       movhi 16128, r0, r{{[0-9]+}}
; CHECK:       mulf.s r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
; CHECK:       jmp [r31]
define float @mul_float_const(float %a) {
  %result = fmul float %a, 0x3FE0000000000000  ; 0.5
  ret float %result
}
