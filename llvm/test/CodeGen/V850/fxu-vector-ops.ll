; RUN: llc -mtriple=v850-unknown-elf -mcpu=g4mh -O2 < %s | FileCheck %s

; Test FXU vector arithmetic operations (v4f32).
; Vector values are loaded/stored from memory since the V850 calling
; convention does not support passing v4f32 in registers.

define void @test_fadd(ptr %pa, ptr %pb, ptr %pc) {
; CHECK-LABEL: test_fadd:
; CHECK: ldv.qw
; CHECK: ldv.qw
; CHECK: addf.s4
; CHECK: stv.qw
  %a = load <4 x float>, ptr %pa, align 16
  %b = load <4 x float>, ptr %pb, align 16
  %r = fadd <4 x float> %a, %b
  store <4 x float> %r, ptr %pc, align 16
  ret void
}

define void @test_fsub(ptr %pa, ptr %pb, ptr %pc) {
; CHECK-LABEL: test_fsub:
; CHECK: ldv.qw
; CHECK: ldv.qw
; CHECK: subf.s4
; CHECK: stv.qw
  %a = load <4 x float>, ptr %pa, align 16
  %b = load <4 x float>, ptr %pb, align 16
  %r = fsub <4 x float> %a, %b
  store <4 x float> %r, ptr %pc, align 16
  ret void
}

define void @test_fmul(ptr %pa, ptr %pb, ptr %pc) {
; CHECK-LABEL: test_fmul:
; CHECK: ldv.qw
; CHECK: ldv.qw
; CHECK: mulf.s4
; CHECK: stv.qw
  %a = load <4 x float>, ptr %pa, align 16
  %b = load <4 x float>, ptr %pb, align 16
  %r = fmul <4 x float> %a, %b
  store <4 x float> %r, ptr %pc, align 16
  ret void
}

define void @test_fdiv(ptr %pa, ptr %pb, ptr %pc) {
; CHECK-LABEL: test_fdiv:
; CHECK: ldv.qw
; CHECK: ldv.qw
; CHECK: divf.s4
; CHECK: stv.qw
  %a = load <4 x float>, ptr %pa, align 16
  %b = load <4 x float>, ptr %pb, align 16
  %r = fdiv <4 x float> %a, %b
  store <4 x float> %r, ptr %pc, align 16
  ret void
}

define void @test_fabs(ptr %pa, ptr %pc) {
; CHECK-LABEL: test_fabs:
; CHECK: ldv.qw
; CHECK: absf.s4
; CHECK: stv.qw
  %a = load <4 x float>, ptr %pa, align 16
  %r = call <4 x float> @llvm.fabs.v4f32(<4 x float> %a)
  store <4 x float> %r, ptr %pc, align 16
  ret void
}

define void @test_fneg(ptr %pa, ptr %pc) {
; CHECK-LABEL: test_fneg:
; CHECK: ldv.qw
; CHECK: negf.s4
; CHECK: stv.qw
  %a = load <4 x float>, ptr %pa, align 16
  %r = fneg <4 x float> %a
  store <4 x float> %r, ptr %pc, align 16
  ret void
}

define void @test_fsqrt(ptr %pa, ptr %pc) {
; CHECK-LABEL: test_fsqrt:
; CHECK: ldv.qw
; CHECK: sqrtf.s4
; CHECK: stv.qw
  %a = load <4 x float>, ptr %pa, align 16
  %r = call <4 x float> @llvm.sqrt.v4f32(<4 x float> %a)
  store <4 x float> %r, ptr %pc, align 16
  ret void
}

define void @test_fma(ptr %pa, ptr %pb, ptr %pc, ptr %pd) {
; CHECK-LABEL: test_fma:
; CHECK: ldv.qw
; CHECK: ldv.qw
; CHECK: ldv.qw
; CHECK: fmaf.s4
; CHECK: stv.qw
  %a = load <4 x float>, ptr %pa, align 16
  %b = load <4 x float>, ptr %pb, align 16
  %c = load <4 x float>, ptr %pc, align 16
  %r = call <4 x float> @llvm.fma.v4f32(<4 x float> %a, <4 x float> %b, <4 x float> %c)
  store <4 x float> %r, ptr %pd, align 16
  ret void
}

define void @test_fminnum(ptr %pa, ptr %pb, ptr %pc) {
; CHECK-LABEL: test_fminnum:
; CHECK: ldv.qw
; CHECK: ldv.qw
; CHECK: minf.s4
; CHECK: stv.qw
  %a = load <4 x float>, ptr %pa, align 16
  %b = load <4 x float>, ptr %pb, align 16
  %r = call <4 x float> @llvm.minnum.v4f32(<4 x float> %a, <4 x float> %b)
  store <4 x float> %r, ptr %pc, align 16
  ret void
}

define void @test_fmaxnum(ptr %pa, ptr %pb, ptr %pc) {
; CHECK-LABEL: test_fmaxnum:
; CHECK: ldv.qw
; CHECK: ldv.qw
; CHECK: maxf.s4
; CHECK: stv.qw
  %a = load <4 x float>, ptr %pa, align 16
  %b = load <4 x float>, ptr %pb, align 16
  %r = call <4 x float> @llvm.maxnum.v4f32(<4 x float> %a, <4 x float> %b)
  store <4 x float> %r, ptr %pc, align 16
  ret void
}

; Test vector loop with aligned accesses (v4sf* pattern)
define void @test_vector_loop(ptr noalias %a, ptr noalias %b, ptr noalias %c, i32 %n) {
; CHECK-LABEL: test_vector_loop:
; CHECK: ldv.qw
; CHECK: ldv.qw
; CHECK: addf.s4
; CHECK: stv.qw
entry:
  %cmp = icmp sgt i32 %n, 0
  br i1 %cmp, label %body, label %exit

body:
  %i = phi i32 [0, %entry], [%i.next, %body]
  %ap = getelementptr <4 x float>, ptr %a, i32 %i
  %bp = getelementptr <4 x float>, ptr %b, i32 %i
  %cp = getelementptr <4 x float>, ptr %c, i32 %i
  %va = load <4 x float>, ptr %ap, align 16
  %vb = load <4 x float>, ptr %bp, align 16
  %vc = fadd <4 x float> %va, %vb
  store <4 x float> %vc, ptr %cp, align 16
  %i.next = add nuw nsw i32 %i, 1
  %cond = icmp eq i32 %i.next, %n
  br i1 %cond, label %exit, label %body

exit:
  ret void
}

declare <4 x float> @llvm.fabs.v4f32(<4 x float>)
declare <4 x float> @llvm.sqrt.v4f32(<4 x float>)
declare <4 x float> @llvm.fma.v4f32(<4 x float>, <4 x float>, <4 x float>)
declare <4 x float> @llvm.minnum.v4f32(<4 x float>, <4 x float>)
declare <4 x float> @llvm.maxnum.v4f32(<4 x float>, <4 x float>)
