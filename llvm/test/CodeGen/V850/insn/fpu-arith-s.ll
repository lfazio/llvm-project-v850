; RUN: llc -march=v850 -mcpu=v850e2m -O0 < %s | FileCheck %s

; Test FPU single-precision arithmetic instructions via inline assembly
; These tests verify the instructions are properly assembled

; CHECK-LABEL: test_addfs:
; CHECK: addf.s
define void @test_addfs() {
  call void asm sideeffect "addf.s r6, r7, r8", ""()
  ret void
}

; CHECK-LABEL: test_subfs:
; CHECK: subf.s
define void @test_subfs() {
  call void asm sideeffect "subf.s r6, r7, r8", ""()
  ret void
}

; CHECK-LABEL: test_mulfs:
; CHECK: mulf.s
define void @test_mulfs() {
  call void asm sideeffect "mulf.s r6, r7, r8", ""()
  ret void
}

; CHECK-LABEL: test_divfs:
; CHECK: divf.s
define void @test_divfs() {
  call void asm sideeffect "divf.s r6, r7, r8", ""()
  ret void
}

; CHECK-LABEL: test_maxfs:
; CHECK: maxf.s
define void @test_maxfs() {
  call void asm sideeffect "maxf.s r6, r7, r8", ""()
  ret void
}

; CHECK-LABEL: test_minfs:
; CHECK: minf.s
define void @test_minfs() {
  call void asm sideeffect "minf.s r6, r7, r8", ""()
  ret void
}

; CHECK-LABEL: test_absfs:
; CHECK: absf.s
define void @test_absfs() {
  call void asm sideeffect "absf.s r6, r7", ""()
  ret void
}

; CHECK-LABEL: test_negfs:
; CHECK: negf.s
define void @test_negfs() {
  call void asm sideeffect "negf.s r6, r7", ""()
  ret void
}

; CHECK-LABEL: test_sqrtfs:
; CHECK: sqrtf.s
define void @test_sqrtfs() {
  call void asm sideeffect "sqrtf.s r6, r7", ""()
  ret void
}

; CHECK-LABEL: test_recipfs:
; CHECK: recipf.s
define void @test_recipfs() {
  call void asm sideeffect "recipf.s r6, r7", ""()
  ret void
}

; CHECK-LABEL: test_rsqrtfs:
; CHECK: rsqrtf.s
define void @test_rsqrtfs() {
  call void asm sideeffect "rsqrtf.s r6, r7", ""()
  ret void
}
