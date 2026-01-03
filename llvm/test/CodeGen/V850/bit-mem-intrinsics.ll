; RUN: llc -mtriple=v850 -mcpu=v850e1 < %s | FileCheck %s

; Test atomic bit manipulation intrinsics for V850E1+

; Test SET1 intrinsic - atomically set bit in memory
define void @test_set1(ptr %addr, i32 %bit) {
; CHECK-LABEL: test_set1:
; CHECK:       set1 r7, [r6]
; CHECK-NEXT:  jmp [r31]
  call void @llvm.v850.set1(ptr %addr, i32 %bit)
  ret void
}

; Test CLR1 intrinsic - atomically clear bit in memory
define void @test_clr1(ptr %addr, i32 %bit) {
; CHECK-LABEL: test_clr1:
; CHECK:       clr1 r7, [r6]
; CHECK-NEXT:  jmp [r31]
  call void @llvm.v850.clr1(ptr %addr, i32 %bit)
  ret void
}

; Test NOT1 intrinsic - atomically toggle bit in memory
define void @test_not1(ptr %addr, i32 %bit) {
; CHECK-LABEL: test_not1:
; CHECK:       not1 r7, [r6]
; CHECK-NEXT:  jmp [r31]
  call void @llvm.v850.not1(ptr %addr, i32 %bit)
  ret void
}

; Test TST1 intrinsic - test bit in memory, returns 1 if bit was 0
define i32 @test_tst1(ptr %addr, i32 %bit) {
; CHECK-LABEL: test_tst1:
; CHECK:       tst1 r7, [r6]
; CHECK-NEXT:  setf z, r10
; CHECK-NEXT:  jmp [r31]
  %result = call i32 @llvm.v850.tst1(ptr %addr, i32 %bit)
  ret i32 %result
}

; Test multiple operations in sequence
define i32 @test_bit_sequence(ptr %addr) {
; CHECK-LABEL: test_bit_sequence:
; CHECK:       set1 r{{[0-9]+}}, [r6]
; CHECK:       clr1 r{{[0-9]+}}, [r6]
; CHECK:       not1 r{{[0-9]+}}, [r6]
; CHECK:       tst1 r{{[0-9]+}}, [r6]
; CHECK:       setf z, r10
  call void @llvm.v850.set1(ptr %addr, i32 3)
  call void @llvm.v850.clr1(ptr %addr, i32 5)
  call void @llvm.v850.not1(ptr %addr, i32 7)
  %result = call i32 @llvm.v850.tst1(ptr %addr, i32 0)
  ret i32 %result
}

declare void @llvm.v850.set1(ptr, i32)
declare void @llvm.v850.clr1(ptr, i32)
declare void @llvm.v850.not1(ptr, i32)
declare i32 @llvm.v850.tst1(ptr, i32)
