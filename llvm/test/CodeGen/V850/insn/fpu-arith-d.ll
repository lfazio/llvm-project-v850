; RUN: llc -march=v850 -mcpu=v850e2m -O0 < %s | FileCheck %s

; Test FPU double-precision arithmetic instructions via inline assembly
; These tests verify the instructions are properly assembled

; CHECK-LABEL: test_addfd:
; CHECK: addf.d
define void @test_addfd() {
  call void asm sideeffect "addf.d r6, r8, r10", ""()
  ret void
}

; CHECK-LABEL: test_subfd:
; CHECK: subf.d
define void @test_subfd() {
  call void asm sideeffect "subf.d r6, r8, r10", ""()
  ret void
}

; CHECK-LABEL: test_mulfd:
; CHECK: mulf.d
define void @test_mulfd() {
  call void asm sideeffect "mulf.d r6, r8, r10", ""()
  ret void
}

; CHECK-LABEL: test_divfd:
; CHECK: divf.d
define void @test_divfd() {
  call void asm sideeffect "divf.d r6, r8, r10", ""()
  ret void
}

; CHECK-LABEL: test_maxfd:
; CHECK: maxf.d
define void @test_maxfd() {
  call void asm sideeffect "maxf.d r6, r8, r10", ""()
  ret void
}

; CHECK-LABEL: test_minfd:
; CHECK: minf.d
define void @test_minfd() {
  call void asm sideeffect "minf.d r6, r8, r10", ""()
  ret void
}

; CHECK-LABEL: test_absfd:
; CHECK: absf.d
define void @test_absfd() {
  call void asm sideeffect "absf.d r6, r8", ""()
  ret void
}

; CHECK-LABEL: test_negfd:
; CHECK: negf.d
define void @test_negfd() {
  call void asm sideeffect "negf.d r6, r8", ""()
  ret void
}

; CHECK-LABEL: test_sqrtfd:
; CHECK: sqrtf.d
define void @test_sqrtfd() {
  call void asm sideeffect "sqrtf.d r6, r8", ""()
  ret void
}

; CHECK-LABEL: test_recipfd:
; CHECK: recipf.d
define void @test_recipfd() {
  call void asm sideeffect "recipf.d r6, r8", ""()
  ret void
}

; CHECK-LABEL: test_rsqrtfd:
; CHECK: rsqrtf.d
define void @test_rsqrtfd() {
  call void asm sideeffect "rsqrtf.d r6, r8", ""()
  ret void
}
