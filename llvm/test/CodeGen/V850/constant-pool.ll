; RUN: llc -mtriple=v850 -mcpu=v850e2m < %s | FileCheck %s

; Test floating-point constant pool handling.
; V850 places FP constants in a constant pool and loads them via address
; materialization (MOVHI+MOVEA) followed by a load instruction.

; Verify constant pool entries are placed in .sdata section before each function.
; CHECK: .section .sdata
; CHECK: .LCPI0_0:
; CHECK-NEXT: .word 0x40490fdb

; CHECK-LABEL: return_float_const:
; CHECK: movhi .LCPI0_0, r0, r{{[0-9]+}}
; CHECK: movea .LCPI0_0, r{{[0-9]+}}, r{{[0-9]+}}
; CHECK: ld.w 0[r{{[0-9]+}}], r{{[0-9]+}}
; CHECK: jmp [r31]
define float @return_float_const() {
  ret float 0x400921FB60000000  ; approximately pi (3.14159...)
}

; CHECK: .section .sdata
; CHECK: .LCPI1_0:
; CHECK-NEXT: .word 0x40200000

; CHECK-LABEL: add_float_const:
; CHECK: movhi .LCPI1_0, r0, r{{[0-9]+}}
; CHECK: movea .LCPI1_0, r{{[0-9]+}}, r{{[0-9]+}}
; CHECK: ld.w 0[r{{[0-9]+}}], r{{[0-9]+}}
; CHECK: addf.s r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
; CHECK: jmp [r31]
define float @add_float_const(float %a) {
  %result = fadd float %a, 0x4004000000000000  ; 2.5
  ret float %result
}

; CHECK: .section .sdata
; CHECK: .LCPI2_0:
; CHECK-NEXT: .word 0x3f000000

; CHECK-LABEL: mul_float_const:
; CHECK: movhi .LCPI2_0, r0, r{{[0-9]+}}
; CHECK: movea .LCPI2_0, r{{[0-9]+}}, r{{[0-9]+}}
; CHECK: ld.w 0[r{{[0-9]+}}], r{{[0-9]+}}
; CHECK: mulf.s r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
; CHECK: jmp [r31]
define float @mul_float_const(float %a) {
  %result = fmul float %a, 0x3FE0000000000000  ; 0.5
  ret float %result
}
