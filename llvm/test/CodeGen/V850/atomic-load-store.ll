; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m -O2 < %s | FileCheck %s

; Test that atomic loads and stores are lowered correctly.
; V850 is single-core in-order, so aligned loads/stores are inherently atomic.
; Memory ordering is handled by SYNCP fences.
;
; Fence insertion follows LLVM's default emitLeadingFence/emitTrailingFence:
; - Leading fence: for release-or-stronger stores
; - Trailing fence: for acquire-or-stronger loads
; On a single-core in-order processor, this provides correct ordering.

; ===== Atomic Loads =====

; Relaxed load - just a regular load, no fence needed
define i32 @atomic_load_relaxed(ptr %p) {
; CHECK-LABEL: atomic_load_relaxed:
; CHECK:       ld.w 0[r6], r10
; CHECK-NOT:   syncp
; CHECK:       jmp [r31]
  %val = load atomic i32, ptr %p monotonic, align 4
  ret i32 %val
}

; Acquire load - load + trailing fence
define i32 @atomic_load_acquire(ptr %p) {
; CHECK-LABEL: atomic_load_acquire:
; CHECK:       ld.w 0[r6], r10
; CHECK-NEXT:  syncp
; CHECK:       jmp [r31]
  %val = load atomic i32, ptr %p acquire, align 4
  ret i32 %val
}

; Seq_cst load - same as acquire on single-core in-order (no store reordering)
define i32 @atomic_load_seq_cst(ptr %p) {
; CHECK-LABEL: atomic_load_seq_cst:
; CHECK:       ld.w 0[r6], r10
; CHECK-NEXT:  syncp
; CHECK:       jmp [r31]
  %val = load atomic i32, ptr %p seq_cst, align 4
  ret i32 %val
}

; ===== Atomic Stores =====

; Relaxed store - just a regular store, no fence needed
define void @atomic_store_relaxed(ptr %p, i32 %val) {
; CHECK-LABEL: atomic_store_relaxed:
; CHECK:       st.w r7, 0[r6]
; CHECK-NOT:   syncp
; CHECK:       jmp [r31]
  store atomic i32 %val, ptr %p monotonic, align 4
  ret void
}

; Release store - leading fence + store
define void @atomic_store_release(ptr %p, i32 %val) {
; CHECK-LABEL: atomic_store_release:
; CHECK:       syncp
; CHECK-NEXT:  st.w r7, 0[r6]
; CHECK-NOT:   syncp
; CHECK:       jmp [r31]
  store atomic i32 %val, ptr %p release, align 4
  ret void
}

; Seq_cst store - leading fence + store + trailing fence
define void @atomic_store_seq_cst(ptr %p, i32 %val) {
; CHECK-LABEL: atomic_store_seq_cst:
; CHECK:       syncp
; CHECK-NEXT:  st.w r7, 0[r6]
; CHECK-NEXT:  syncp
; CHECK:       jmp [r31]
  store atomic i32 %val, ptr %p seq_cst, align 4
  ret void
}

; ===== Atomic Fence =====

define void @atomic_fence_acquire() {
; CHECK-LABEL: atomic_fence_acquire:
; CHECK:       syncp
; CHECK:       jmp [r31]
  fence acquire
  ret void
}

define void @atomic_fence_seq_cst() {
; CHECK-LABEL: atomic_fence_seq_cst:
; CHECK:       syncp
; CHECK:       jmp [r31]
  fence seq_cst
  ret void
}
