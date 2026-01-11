; RUN: llc -mtriple=v850 -mcpu=v850e2m < %s | FileCheck %s

;===----------------------------------------------------------------------===;
; Test memory barrier intrinsics
;
; V850 provides three synchronization instructions:
; - SYNCP: Pipeline synchronization (full barrier)
; - SYNCM: Memory synchronization
; - SYNCE: Exception synchronization
;===----------------------------------------------------------------------===;

declare void @llvm.v850.syncp()
declare void @llvm.v850.syncm()
declare void @llvm.v850.synce()

;===----------------------------------------------------------------------===;
; Basic Barrier Tests
;===----------------------------------------------------------------------===;

; Test SYNCP (full pipeline barrier)
; CHECK-LABEL: test_syncp:
; CHECK: syncp
; CHECK: jmp [r31]
define void @test_syncp() {
entry:
  call void @llvm.v850.syncp()
  ret void
}

; Test SYNCM (memory barrier)
; CHECK-LABEL: test_syncm:
; CHECK: syncm
; CHECK: jmp [r31]
define void @test_syncm() {
entry:
  call void @llvm.v850.syncm()
  ret void
}

; Test SYNCE (exception barrier)
; CHECK-LABEL: test_synce:
; CHECK: synce
; CHECK: jmp [r31]
define void @test_synce() {
entry:
  call void @llvm.v850.synce()
  ret void
}

;===----------------------------------------------------------------------===;
; Combined Barrier Tests
;===----------------------------------------------------------------------===;

; Test multiple barriers in sequence
; CHECK-LABEL: test_multiple_barriers:
; CHECK: syncm
; CHECK: syncp
; CHECK: jmp [r31]
define void @test_multiple_barriers() {
entry:
  call void @llvm.v850.syncm()
  call void @llvm.v850.syncp()
  ret void
}

; Test barrier between memory operations
; CHECK-LABEL: test_barrier_between_stores:
; CHECK: st.w
; CHECK: syncp
; CHECK: st.w
; CHECK: jmp [r31]
define void @test_barrier_between_stores(ptr %p, i32 %a, i32 %b) {
entry:
  store i32 %a, ptr %p, align 4
  call void @llvm.v850.syncp()
  %p2 = getelementptr i32, ptr %p, i32 1
  store i32 %b, ptr %p2, align 4
  ret void
}

; Test barrier between load and store
; CHECK-LABEL: test_barrier_load_store:
; CHECK: ld.w
; CHECK: syncm
; CHECK: st.w
; CHECK: jmp [r31]
define i32 @test_barrier_load_store(ptr %p, i32 %val) {
entry:
  %old = load i32, ptr %p, align 4
  call void @llvm.v850.syncm()
  store i32 %val, ptr %p, align 4
  ret i32 %old
}
