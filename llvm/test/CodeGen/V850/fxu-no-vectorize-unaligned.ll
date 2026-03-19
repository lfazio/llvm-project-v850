; RUN: llc -mtriple=v850-unknown-elf -mcpu=g4mh -O2 < %s | FileCheck %s

; Test that unaligned vector accesses are scalarized through the stack.
; V850 FXU requires 16-byte alignment for LDV.QW/STV.QW; misaligned
; access causes MAE (Misalignment Exception).
;
; The backend may use LDV.QW/STV.QW internally for stack operations
; (which are properly aligned), but the actual unaligned source/dest
; access must use scalar LD.W/ST.W.

; Unaligned vector load: scalar LD.W from source, build on stack, LDV.QW
define void @test_unaligned_load(ptr %p, ptr %out) {
; CHECK-LABEL: test_unaligned_load:
; CHECK: ld.w {{.*}}[r6]
; CHECK: ldv.qw
; CHECK: stv.qw {{.*}}0[r7]
  %v = load <4 x float>, ptr %p, align 4
  store <4 x float> %v, ptr %out, align 16
  ret void
}

; Unaligned vector store: LDV.QW from source, STV.QW to stack, scalar ST.W
define void @test_unaligned_store(ptr %in, ptr %p) {
; CHECK-LABEL: test_unaligned_store:
; CHECK: ldv.qw 0[r6]
; CHECK: st.w {{.*}}[r7]
  %v = load <4 x float>, ptr %in, align 16
  store <4 x float> %v, ptr %p, align 4
  ret void
}
