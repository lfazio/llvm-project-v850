; RUN: llc -mtriple=v850 -mcpu=v850e2m < %s | FileCheck %s

; Test SIMD-like operations optimization.
; V850 doesn't have true SIMD, but has efficient instructions for:
; - Byte/halfword swapping (BSW, BSH, HSW, HSH)
; - Saturating arithmetic (SATADD, SATSUB)
; - FPU min/max (MINF.S, MAXF.S)
; - FMA operations (MADDF.S, NMADDF.S)

;; Byte Swap Operations

; CHECK-LABEL: test_bswap32:
; CHECK: bsw r6, r10
; CHECK-NEXT: jmp [r31]
define i32 @test_bswap32(i32 %x) {
  %result = call i32 @llvm.bswap.i32(i32 %x)
  ret i32 %result
}

; Optimized: bswap16 now uses BSH instead of BSW + SHR 16
; CHECK-LABEL: test_bswap16:
; CHECK: bsh r6, r10
; CHECK-NEXT: jmp [r31]
define i16 @test_bswap16(i16 %x) {
  %result = call i16 @llvm.bswap.i16(i16 %x)
  ret i16 %result
}

;; Rotate Operations

; Rotate left by 16 uses HSW
; CHECK-LABEL: test_rotl16:
; CHECK: hsw r6, r10
; CHECK-NEXT: jmp [r31]
define i32 @test_rotl16(i32 %x) {
  %shl = shl i32 %x, 16
  %shr = lshr i32 %x, 16
  %result = or i32 %shl, %shr
  ret i32 %result
}

; Rotate right by 16 also uses HSW
; CHECK-LABEL: test_rotr16:
; CHECK: hsw r6, r10
; CHECK-NEXT: jmp [r31]
define i32 @test_rotr16(i32 %x) {
  %shr = lshr i32 %x, 16
  %shl = shl i32 %x, 16
  %result = or i32 %shr, %shl
  ret i32 %result
}

;; Saturating Arithmetic

; CHECK-LABEL: test_sadd_sat:
; CHECK: satadd r7, r6, r10
; CHECK-NEXT: jmp [r31]
define i32 @test_sadd_sat(i32 %a, i32 %b) {
  %result = call i32 @llvm.sadd.sat.i32(i32 %a, i32 %b)
  ret i32 %result
}

; CHECK-LABEL: test_ssub_sat:
; CHECK: satsub r7, r6, r10
; CHECK-NEXT: jmp [r31]
define i32 @test_ssub_sat(i32 %a, i32 %b) {
  %result = call i32 @llvm.ssub.sat.i32(i32 %a, i32 %b)
  ret i32 %result
}

;; FPU Min/Max Operations

; CHECK-LABEL: test_fmin:
; CHECK: minf.s r7, r6, r10
; CHECK-NEXT: jmp [r31]
define float @test_fmin(float %a, float %b) {
  %result = call float @llvm.minnum.f32(float %a, float %b)
  ret float %result
}

; CHECK-LABEL: test_fmax:
; CHECK: maxf.s r7, r6, r10
; CHECK-NEXT: jmp [r31]
define float @test_fmax(float %a, float %b) {
  %result = call float @llvm.maxnum.f32(float %a, float %b)
  ret float %result
}

;; FMA Operations

; CHECK-LABEL: test_fma:
; CHECK: maddf.s r6, r7, r8, r10
; CHECK-NEXT: jmp [r31]
define float @test_fma(float %a, float %b, float %c) {
  %result = call float @llvm.fma.f32(float %a, float %b, float %c)
  ret float %result
}

; Negate FMA optimized to NMADDF.S
; CHECK-LABEL: test_nfma:
; CHECK: nmaddf.s r6, r7, r8, r10
; CHECK-NEXT: jmp [r31]
define float @test_nfma(float %a, float %b, float %c) {
  %fma = call float @llvm.fma.f32(float %a, float %b, float %c)
  %result = fneg float %fma
  ret float %result
}

declare i32 @llvm.bswap.i32(i32)
declare i16 @llvm.bswap.i16(i16)
declare i32 @llvm.sadd.sat.i32(i32, i32)
declare i32 @llvm.ssub.sat.i32(i32, i32)
declare float @llvm.minnum.f32(float, float)
declare float @llvm.maxnum.f32(float, float)
declare float @llvm.fma.f32(float, float, float)
