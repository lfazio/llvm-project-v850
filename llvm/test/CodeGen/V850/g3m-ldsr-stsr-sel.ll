; RUN: llc -mtriple=v850-unknown-elf -mcpu=g3m -O2 < %s | FileCheck %s

; Test LDSR/STSR with selID (group specification) for RH850G3M.
; RH850G3M extends system register access with a selID field that
; selects the register group (0-31). This enables access to registers
; beyond the base group (selID=0).

declare void @llvm.v850.ldsr.sel(i32, i32, i32)
declare i32 @llvm.v850.stsr.sel(i32, i32)

; --- Group 1: Machine Configuration ---

; Write to EBASE (regID=3, selID=1)
define void @test_ldsr_ebase(i32 %val) {
; CHECK-LABEL: test_ldsr_ebase:
; CHECK:       ldsr r6, 3, 1
  call void @llvm.v850.ldsr.sel(i32 %val, i32 3, i32 1)
  ret void
}

; Read from EBASE (regID=3, selID=1)
define i32 @test_stsr_ebase() {
; CHECK-LABEL: test_stsr_ebase:
; CHECK:       stsr 3, r10, 1
  %r = call i32 @llvm.v850.stsr.sel(i32 3, i32 1)
  ret i32 %r
}

; Write to INTBP (regID=4, selID=1)
define void @test_ldsr_intbp(i32 %val) {
; CHECK-LABEL: test_ldsr_intbp:
; CHECK:       ldsr r6, 4, 1
  call void @llvm.v850.ldsr.sel(i32 %val, i32 4, i32 1)
  ret void
}

; Read from INTBP (regID=4, selID=1)
define i32 @test_stsr_intbp() {
; CHECK-LABEL: test_stsr_intbp:
; CHECK:       stsr 4, r10, 1
  %r = call i32 @llvm.v850.stsr.sel(i32 4, i32 1)
  ret i32 %r
}

; --- Group 2: Thread/Interrupt ---

; Read from MEA (regID=6, selID=2)
define i32 @test_stsr_mea() {
; CHECK-LABEL: test_stsr_mea:
; CHECK:       stsr 6, r10, 2
  %r = call i32 @llvm.v850.stsr.sel(i32 6, i32 2)
  ret i32 %r
}

; Read from MEI (regID=8, selID=2)
define i32 @test_stsr_mei() {
; CHECK-LABEL: test_stsr_mei:
; CHECK:       stsr 8, r10, 2
  %r = call i32 @llvm.v850.stsr.sel(i32 8, i32 2)
  ret i32 %r
}

; Read from ISPR (regID=10, selID=2)
define i32 @test_stsr_ispr() {
; CHECK-LABEL: test_stsr_ispr:
; CHECK:       stsr 10, r10, 2
  %r = call i32 @llvm.v850.stsr.sel(i32 10, i32 2)
  ret i32 %r
}

; Write to PMR (regID=11, selID=2)
define void @test_ldsr_pmr(i32 %val) {
; CHECK-LABEL: test_ldsr_pmr:
; CHECK:       ldsr r6, 11, 2
  call void @llvm.v850.ldsr.sel(i32 %val, i32 11, i32 2)
  ret void
}

; --- Multiple accesses in a function ---

define i32 @test_read_write_ebase(i32 %val) {
; CHECK-LABEL: test_read_write_ebase:
; CHECK:       stsr 3, r10, 1
; CHECK:       ldsr r6, 3, 1
  %old = call i32 @llvm.v850.stsr.sel(i32 3, i32 1)
  call void @llvm.v850.ldsr.sel(i32 %val, i32 3, i32 1)
  ret i32 %old
}
