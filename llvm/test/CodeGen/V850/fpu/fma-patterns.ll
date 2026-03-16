; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m < %s | FileCheck %s

; Test FMA instruction selection patterns:
; MADDF.S:  fma(a, b, c)             -> reg4 = (reg2 * reg1) + reg3
; MSUBF.S:  fma(a, b, -c)            -> reg4 = (reg2 * reg1) - reg3
; NMADDF.S: -(fma(a, b, c))          -> reg4 = -((reg2 * reg1) + reg3)
; NMSUBF.S: -(fma(a, b, -c))         -> reg4 = -((reg2 * reg1) - reg3)

;===----------------------------------------------------------------------===;
; MADDF.S - fused multiply-add via llvm.fma intrinsic
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_fma:
; CHECK:       maddf.s r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}, r10
; CHECK-NEXT:  jmp [r31]
define float @test_fma(float %a, float %b, float %c) {
  %r = call float @llvm.fma.f32(float %a, float %b, float %c)
  ret float %r
}

;===----------------------------------------------------------------------===;
; MSUBF.S - fused multiply-subtract: fma(a, b, -c)
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_fmsub:
; CHECK:       msubf.s r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}, r10
; CHECK-NEXT:  jmp [r31]
define float @test_fmsub(float %a, float %b, float %c) {
  %nc = fneg float %c
  %r = call float @llvm.fma.f32(float %a, float %b, float %nc)
  ret float %r
}

;===----------------------------------------------------------------------===;
; NMADDF.S - negated fused multiply-add: -(fma(a, b, c))
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_nfma:
; CHECK:       nmaddf.s r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}, r10
; CHECK-NEXT:  jmp [r31]
define float @test_nfma(float %a, float %b, float %c) {
  %fma = call float @llvm.fma.f32(float %a, float %b, float %c)
  %r = fneg float %fma
  ret float %r
}

;===----------------------------------------------------------------------===;
; NMSUBF.S - negated fused multiply-subtract: -(fma(a, b, -c))
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_nfmsub:
; CHECK:       nmsubf.s r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}, r10
; CHECK-NEXT:  jmp [r31]
define float @test_nfmsub(float %a, float %b, float %c) {
  %nc = fneg float %c
  %fma = call float @llvm.fma.f32(float %a, float %b, float %nc)
  %r = fneg float %fma
  ret float %r
}

;===----------------------------------------------------------------------===;
; Contracted FMA - fadd(fmul(a, b), c) with contract flag
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_contract_add:
; CHECK:       maddf.s r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}, r10
; CHECK-NEXT:  jmp [r31]
define float @test_contract_add(float %a, float %b, float %c) {
  %mul = fmul contract float %a, %b
  %add = fadd contract float %mul, %c
  ret float %add
}

;===----------------------------------------------------------------------===;
; Contracted FMSUB - fsub(fmul(a, b), c) with contract flag
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_contract_sub:
; CHECK:       msubf.s r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}, r10
; CHECK-NEXT:  jmp [r31]
define float @test_contract_sub(float %a, float %b, float %c) {
  %mul = fmul contract float %a, %b
  %sub = fsub contract float %mul, %c
  ret float %sub
}

;===----------------------------------------------------------------------===;
; Contracted FMA - fadd(c, fmul(a, b)) with contract flag (commuted)
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_contract_add_commuted:
; CHECK:       maddf.s r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}, r10
; CHECK-NEXT:  jmp [r31]
define float @test_contract_add_commuted(float %a, float %b, float %c) {
  %mul = fmul contract float %a, %b
  %add = fadd contract float %c, %mul
  ret float %add
}

;===----------------------------------------------------------------------===;
; Without contract flag - should NOT form FMA
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_no_contract:
; CHECK:       mulf.s
; CHECK:       addf.s
define float @test_no_contract(float %a, float %b, float %c) {
  %mul = fmul float %a, %b
  %add = fadd float %mul, %c
  ret float %add
}

declare float @llvm.fma.f32(float, float, float)
