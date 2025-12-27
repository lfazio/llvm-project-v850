; RUN: llc -march=v850 -mcpu=v850e2m -O0 < %s | FileCheck %s

; Test FPU conversion instructions via inline assembly
; These tests verify the instructions are properly assembled

; Single/Double conversion
; CHECK-LABEL: test_cvtf_ds:
; CHECK: cvtf.ds
define void @test_cvtf_ds() {
  call void asm sideeffect "cvtf.ds r6, r7", ""()
  ret void
}

; CHECK-LABEL: test_cvtf_sd:
; CHECK: cvtf.sd
define void @test_cvtf_sd() {
  call void asm sideeffect "cvtf.sd r6, r8", ""()
  ret void
}

; Integer to Float (signed)
; CHECK-LABEL: test_cvtf_ws:
; CHECK: cvtf.ws
define void @test_cvtf_ws() {
  call void asm sideeffect "cvtf.ws r6, r7", ""()
  ret void
}

; CHECK-LABEL: test_cvtf_wd:
; CHECK: cvtf.wd
define void @test_cvtf_wd() {
  call void asm sideeffect "cvtf.wd r6, r8", ""()
  ret void
}

; CHECK-LABEL: test_cvtf_ls:
; CHECK: cvtf.ls
define void @test_cvtf_ls() {
  call void asm sideeffect "cvtf.ls r6, r7", ""()
  ret void
}

; CHECK-LABEL: test_cvtf_ld:
; CHECK: cvtf.ld
define void @test_cvtf_ld() {
  call void asm sideeffect "cvtf.ld r6, r8", ""()
  ret void
}

; Float to Integer (signed)
; CHECK-LABEL: test_cvtf_sw:
; CHECK: cvtf.sw
define void @test_cvtf_sw() {
  call void asm sideeffect "cvtf.sw r6, r7", ""()
  ret void
}

; CHECK-LABEL: test_cvtf_dw:
; CHECK: cvtf.dw
define void @test_cvtf_dw() {
  call void asm sideeffect "cvtf.dw r6, r8", ""()
  ret void
}

; CHECK-LABEL: test_cvtf_sl:
; CHECK: cvtf.sl
define void @test_cvtf_sl() {
  call void asm sideeffect "cvtf.sl r6, r8", ""()
  ret void
}

; CHECK-LABEL: test_cvtf_dl:
; CHECK: cvtf.dl
define void @test_cvtf_dl() {
  call void asm sideeffect "cvtf.dl r6, r8", ""()
  ret void
}

; Integer to Float (unsigned)
; CHECK-LABEL: test_cvtf_uws:
; CHECK: cvtf.uws
define void @test_cvtf_uws() {
  call void asm sideeffect "cvtf.uws r6, r7", ""()
  ret void
}

; CHECK-LABEL: test_cvtf_uwd:
; CHECK: cvtf.uwd
define void @test_cvtf_uwd() {
  call void asm sideeffect "cvtf.uwd r6, r8", ""()
  ret void
}

; Float to Integer (unsigned)
; CHECK-LABEL: test_cvtf_suw:
; CHECK: cvtf.suw
define void @test_cvtf_suw() {
  call void asm sideeffect "cvtf.suw r6, r7", ""()
  ret void
}

; CHECK-LABEL: test_cvtf_duw:
; CHECK: cvtf.duw
define void @test_cvtf_duw() {
  call void asm sideeffect "cvtf.duw r6, r8", ""()
  ret void
}
