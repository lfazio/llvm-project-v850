; RUN: llc -mtriple=v850-unknown-elf -mcpu=g3m -O2 < %s | FileCheck %s

; Test CACHE and PREF instruction selection for RH850G3M.

declare void @llvm.v850.cache(i32 immarg, ptr)
declare void @llvm.v850.pref(i32 immarg, ptr)

; --- CACHE instruction ---

define void @test_cache_chbii(ptr %addr) {
; CHECK-LABEL: test_cache_chbii:
; CHECK:       cache 0, [r6]
  call void @llvm.v850.cache(i32 0, ptr %addr)
  ret void
}

define void @test_cache_cibii(ptr %addr) {
; CHECK-LABEL: test_cache_cibii:
; CHECK:       cache 32, [r6]
  call void @llvm.v850.cache(i32 32, ptr %addr)
  ret void
}

define void @test_cache_cfali(ptr %addr) {
; CHECK-LABEL: test_cache_cfali:
; CHECK:       cache 48, [r6]
  call void @llvm.v850.cache(i32 48, ptr %addr)
  ret void
}

; --- PREF instruction ---

define void @test_pref(ptr %addr) {
; CHECK-LABEL: test_pref:
; CHECK:       pref 0, [r6]
  call void @llvm.v850.pref(i32 0, ptr %addr)
  ret void
}
