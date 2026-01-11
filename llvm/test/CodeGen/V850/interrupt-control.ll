; RUN: llc -mtriple=v850 -mcpu=v850e2m < %s | FileCheck %s

;===----------------------------------------------------------------------===;
; Test interrupt control intrinsics
;
; V850 provides instructions to enable/disable interrupts:
; - DI: Disable interrupts (sets ID bit in PSW)
; - EI: Enable interrupts (clears ID bit in PSW)
;===----------------------------------------------------------------------===;

declare void @llvm.v850.di()
declare void @llvm.v850.ei()

;===----------------------------------------------------------------------===;
; Basic Interrupt Control Tests
;===----------------------------------------------------------------------===;

; Test DI (disable interrupts)
; CHECK-LABEL: test_di:
; CHECK: di
; CHECK: jmp [r31]
define void @test_di() {
entry:
  call void @llvm.v850.di()
  ret void
}

; Test EI (enable interrupts)
; CHECK-LABEL: test_ei:
; CHECK: ei
; CHECK: jmp [r31]
define void @test_ei() {
entry:
  call void @llvm.v850.ei()
  ret void
}

;===----------------------------------------------------------------------===;
; Critical Section Pattern Tests
;===----------------------------------------------------------------------===;

; Test critical section pattern: DI ... EI
; CHECK-LABEL: test_critical_section:
; CHECK: di
; CHECK: st.w
; CHECK: ei
; CHECK: jmp [r31]
define void @test_critical_section(ptr %p, i32 %val) {
entry:
  call void @llvm.v850.di()
  store volatile i32 %val, ptr %p, align 4
  call void @llvm.v850.ei()
  ret void
}

; Test nested critical sections (common in embedded systems)
; CHECK-LABEL: test_nested_critical:
; CHECK: di
; CHECK: di
; CHECK: ei
; CHECK: ei
; CHECK: jmp [r31]
define void @test_nested_critical() {
entry:
  call void @llvm.v850.di()
  call void @llvm.v850.di()
  call void @llvm.v850.ei()
  call void @llvm.v850.ei()
  ret void
}

;===----------------------------------------------------------------------===;
; Combined with Memory Barriers
;===----------------------------------------------------------------------===;

declare void @llvm.v850.syncp()

; Test DI + memory barrier + EI pattern
; CHECK-LABEL: test_di_barrier_ei:
; CHECK: di
; CHECK: syncp
; CHECK: ei
; CHECK: jmp [r31]
define void @test_di_barrier_ei() {
entry:
  call void @llvm.v850.di()
  call void @llvm.v850.syncp()
  call void @llvm.v850.ei()
  ret void
}

; Test atomic-like operation pattern
; CHECK-LABEL: test_atomic_increment:
; CHECK: di
; CHECK: ld.w
; CHECK: add
; CHECK: st.w
; CHECK: ei
; CHECK: jmp [r31]
define i32 @test_atomic_increment(ptr %p) {
entry:
  call void @llvm.v850.di()
  %val = load volatile i32, ptr %p, align 4
  %inc = add i32 %val, 1
  store volatile i32 %inc, ptr %p, align 4
  call void @llvm.v850.ei()
  ret i32 %val
}
