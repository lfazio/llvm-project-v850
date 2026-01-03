; RUN: llc -mtriple=v850 -mcpu=v850e2m -O2 < %s | FileCheck %s

;============================================================================
; Atomic Compare-and-Swap (directly uses CAXI)
;============================================================================

; CHECK-LABEL: test_cmpxchg:
; CHECK:       caxi [r6], r7, r8
; CHECK:       jmp [r31]
define i32 @test_cmpxchg(ptr %ptr, i32 %expected, i32 %new) {
  %pair = cmpxchg ptr %ptr, i32 %expected, i32 %new seq_cst seq_cst
  %old = extractvalue { i32, i1 } %pair, 0
  ret i32 %old
}

;============================================================================
; Atomic RMW Operations (expanded to CAXI loops)
;============================================================================

; CHECK-LABEL: test_atomic_add:
; CHECK:       ld.w 0[r6]
; CHECK:       .LBB{{[0-9]+}}_1:
; CHECK:       add
; CHECK:       caxi [r6]
; CHECK:       bnz .LBB{{[0-9]+}}_1
; CHECK:       jmp [r31]
define i32 @test_atomic_add(ptr %ptr, i32 %val) {
  %old = atomicrmw add ptr %ptr, i32 %val seq_cst
  ret i32 %old
}

; CHECK-LABEL: test_atomic_sub:
; CHECK:       ld.w 0[r6]
; CHECK:       .LBB{{[0-9]+}}_1:
; CHECK:       sub
; CHECK:       caxi [r6]
; CHECK:       bnz .LBB{{[0-9]+}}_1
; CHECK:       jmp [r31]
define i32 @test_atomic_sub(ptr %ptr, i32 %val) {
  %old = atomicrmw sub ptr %ptr, i32 %val seq_cst
  ret i32 %old
}

; CHECK-LABEL: test_atomic_and:
; CHECK:       ld.w 0[r6]
; CHECK:       .LBB{{[0-9]+}}_1:
; CHECK:       and
; CHECK:       caxi [r6]
; CHECK:       bnz .LBB{{[0-9]+}}_1
; CHECK:       jmp [r31]
define i32 @test_atomic_and(ptr %ptr, i32 %val) {
  %old = atomicrmw and ptr %ptr, i32 %val seq_cst
  ret i32 %old
}

; CHECK-LABEL: test_atomic_or:
; CHECK:       ld.w 0[r6]
; CHECK:       .LBB{{[0-9]+}}_1:
; CHECK:       or
; CHECK:       caxi [r6]
; CHECK:       bnz .LBB{{[0-9]+}}_1
; CHECK:       jmp [r31]
define i32 @test_atomic_or(ptr %ptr, i32 %val) {
  %old = atomicrmw or ptr %ptr, i32 %val seq_cst
  ret i32 %old
}

; CHECK-LABEL: test_atomic_xor:
; CHECK:       ld.w 0[r6]
; CHECK:       .LBB{{[0-9]+}}_1:
; CHECK:       xor
; CHECK:       caxi [r6]
; CHECK:       bnz .LBB{{[0-9]+}}_1
; CHECK:       jmp [r31]
define i32 @test_atomic_xor(ptr %ptr, i32 %val) {
  %old = atomicrmw xor ptr %ptr, i32 %val seq_cst
  ret i32 %old
}

; CHECK-LABEL: test_atomic_xchg:
; CHECK:       ld.w 0[r6]
; CHECK:       .LBB{{[0-9]+}}_1:
; CHECK:       mov
; CHECK:       caxi [r6]
; CHECK:       bnz .LBB{{[0-9]+}}_1
; CHECK:       jmp [r31]
define i32 @test_atomic_xchg(ptr %ptr, i32 %val) {
  %old = atomicrmw xchg ptr %ptr, i32 %val seq_cst
  ret i32 %old
}
