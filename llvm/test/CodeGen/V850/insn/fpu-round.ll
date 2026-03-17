; RUN: llc -march=v850 -mcpu=v850e2m -O0 < %s | FileCheck %s

; Test FPU rounding instructions via inline assembly
; These tests verify the instructions are properly assembled

; TRNCF - Truncate (round toward zero)
; CHECK-LABEL: test_trncf_sw:
; CHECK: trncf.sw
define void @test_trncf_sw() {
  call void asm sideeffect "trncf.sw r6, r7", ""()
  ret void
}

; CHECK-LABEL: test_trncf_dw:
; CHECK: trncf.dw
define void @test_trncf_dw() {
  call void asm sideeffect "trncf.dw r6, r8", ""()
  ret void
}

; CHECK-LABEL: test_trncf_sl:
; CHECK: trncf.sl
define void @test_trncf_sl() {
  ; reg3 is DPR (i64 output)
  call void asm sideeffect "trncf.sl r6, d8", ""()
  ret void
}

; CHECK-LABEL: test_trncf_dl:
; CHECK: trncf.dl
define void @test_trncf_dl() {
  ; reg2 is dprreg (f64 input), reg3 is DPR (i64 output)
  call void asm sideeffect "trncf.dl r6, d8", ""()
  ret void
}

; CHECK-LABEL: test_trncf_suw:
; CHECK: trncf.suw
define void @test_trncf_suw() {
  call void asm sideeffect "trncf.suw r6, r7", ""()
  ret void
}

; CHECK-LABEL: test_trncf_duw:
; CHECK: trncf.duw
define void @test_trncf_duw() {
  call void asm sideeffect "trncf.duw r6, r8", ""()
  ret void
}

; CEILF - Ceiling (round toward +infinity)
; CHECK-LABEL: test_ceilf_sw:
; CHECK: ceilf.sw
define void @test_ceilf_sw() {
  call void asm sideeffect "ceilf.sw r6, r7", ""()
  ret void
}

; CHECK-LABEL: test_ceilf_dw:
; CHECK: ceilf.dw
define void @test_ceilf_dw() {
  call void asm sideeffect "ceilf.dw r6, r8", ""()
  ret void
}

; CHECK-LABEL: test_ceilf_sl:
; CHECK: ceilf.sl
define void @test_ceilf_sl() {
  ; reg3 is DPR (i64 output)
  call void asm sideeffect "ceilf.sl r6, d8", ""()
  ret void
}

; CHECK-LABEL: test_ceilf_dl:
; CHECK: ceilf.dl
define void @test_ceilf_dl() {
  ; reg2 is dprreg (f64 input), reg3 is DPR (i64 output)
  call void asm sideeffect "ceilf.dl r6, d8", ""()
  ret void
}

; FLOORF - Floor (round toward -infinity)
; CHECK-LABEL: test_floorf_sw:
; CHECK: floorf.sw
define void @test_floorf_sw() {
  call void asm sideeffect "floorf.sw r6, r7", ""()
  ret void
}

; CHECK-LABEL: test_floorf_dw:
; CHECK: floorf.dw
define void @test_floorf_dw() {
  call void asm sideeffect "floorf.dw r6, r8", ""()
  ret void
}

; CHECK-LABEL: test_floorf_sl:
; CHECK: floorf.sl
define void @test_floorf_sl() {
  ; reg3 is DPR (i64 output)
  call void asm sideeffect "floorf.sl r6, d8", ""()
  ret void
}

; CHECK-LABEL: test_floorf_dl:
; CHECK: floorf.dl
define void @test_floorf_dl() {
  ; reg2 is dprreg (f64 input), reg3 is DPR (i64 output)
  call void asm sideeffect "floorf.dl r6, d8", ""()
  ret void
}
