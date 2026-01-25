; RUN: llc -march=v850 -mcpu=v850e1 < %s | FileCheck %s --check-prefix=V850E1
; RUN: llc -march=v850 -mcpu=v850 < %s | FileCheck %s --check-prefix=V850

; Test PREPARE/DISPOSE instruction usage for V850E1+.
; PREPARE/DISPOSE combine callee-saved register save/restore into single instructions.

declare void @external()

; Non-leaf function - V850E1+ should use PREPARE/DISPOSE, base V850 uses st.w/ld.w
define void @test_save_lp() {
; V850E1-LABEL: test_save_lp:
; V850E1: prepare 2048, 0
; V850E1: jarl external, r31
; V850E1: dispose 0, 2048, [r31]

; V850-LABEL: test_save_lp:
; V850: st.w r31
; V850: jarl external, r31
; V850: ld.w {{.*}}, r31
; V850: jmp [r31]
  call void @external()
  ret void
}

; Function with multiple calls - should use PREPARE/DISPOSE
define i32 @test_multiple_csr(i32 %a) {
; V850E1-LABEL: test_multiple_csr:
; V850E1: prepare
; V850E1: jarl
; V850E1: jarl
; V850E1: dispose
entry:
  %r1 = call i32 @bar(i32 %a)
  %r2 = add i32 %r1, %a
  %r3 = call i32 @bar(i32 %r2)
  ret i32 %r3
}

declare i32 @bar(i32)

; When frame pointer is used, fall back to individual stores
; because SP restoration from FP conflicts with DISPOSE
define void @test_with_fp() "frame-pointer"="all" {
; V850E1-LABEL: test_with_fp:
; V850E1: st.w r29
; V850E1: st.w r31
; V850E1: jarl external, r31
  call void @external()
  ret void
}

; Leaf function - no PREPARE/DISPOSE needed (no CSRs)
define i32 @test_leaf(i32 %a, i32 %b) {
; V850E1-LABEL: test_leaf:
; V850E1-NOT: prepare
; V850E1-NOT: dispose
; V850E1: add r7, r6
; V850E1: jmp [r31]
  %r = add i32 %a, %b
  ret i32 %r
}
