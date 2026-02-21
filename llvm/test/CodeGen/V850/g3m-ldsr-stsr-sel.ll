; RUN: llc -mtriple=v850-unknown-elf -mcpu=g3m -O2 < %s | FileCheck %s

; Test LDSR/STSR with unified 10-bit encoding for RH850G3M.
; The unified encoding is: (selID << 5) | regID.
; Named registers are used in assembly output when the encoding matches
; a known register for the active CPU.

declare void @llvm.v850.ldsr(i32, i32)
declare i32 @llvm.v850.stsr(i32)

; --- Group 1: Machine Configuration (selID=1) ---

; Write to EBASE (regID=3, selID=1, enc=35)
define void @test_ldsr_ebase(i32 %val) {
; CHECK-LABEL: test_ldsr_ebase:
; CHECK:       ldsr r6, ebase
  call void @llvm.v850.ldsr(i32 %val, i32 35)
  ret void
}

; Read from EBASE (regID=3, selID=1, enc=35)
define i32 @test_stsr_ebase() {
; CHECK-LABEL: test_stsr_ebase:
; CHECK:       stsr ebase, r10
  %r = call i32 @llvm.v850.stsr(i32 35)
  ret i32 %r
}

; Write to INTBP (regID=4, selID=1, enc=36)
define void @test_ldsr_intbp(i32 %val) {
; CHECK-LABEL: test_ldsr_intbp:
; CHECK:       ldsr r6, intbp
  call void @llvm.v850.ldsr(i32 %val, i32 36)
  ret void
}

; Read from INTBP (regID=4, selID=1, enc=36)
define i32 @test_stsr_intbp() {
; CHECK-LABEL: test_stsr_intbp:
; CHECK:       stsr intbp, r10
  %r = call i32 @llvm.v850.stsr(i32 36)
  ret i32 %r
}

; --- Group 2: Thread/Interrupt (selID=2) ---

; Read from MEA (regID=6, selID=2, enc=70)
define i32 @test_stsr_mea() {
; CHECK-LABEL: test_stsr_mea:
; CHECK:       stsr mea, r10
  %r = call i32 @llvm.v850.stsr(i32 70)
  ret i32 %r
}

; Read from MEI (regID=8, selID=2, enc=72)
define i32 @test_stsr_mei() {
; CHECK-LABEL: test_stsr_mei:
; CHECK:       stsr mei, r10
  %r = call i32 @llvm.v850.stsr(i32 72)
  ret i32 %r
}

; Read from ISPR (regID=10, selID=2, enc=74)
define i32 @test_stsr_ispr() {
; CHECK-LABEL: test_stsr_ispr:
; CHECK:       stsr ispr, r10
  %r = call i32 @llvm.v850.stsr(i32 74)
  ret i32 %r
}

; Write to PMR (regID=11, selID=2, enc=75)
define void @test_ldsr_pmr(i32 %val) {
; CHECK-LABEL: test_ldsr_pmr:
; CHECK:       ldsr r6, pmr
  call void @llvm.v850.ldsr(i32 %val, i32 75)
  ret void
}

; --- Multiple accesses in a function ---

define i32 @test_read_write_ebase(i32 %val) {
; CHECK-LABEL: test_read_write_ebase:
; CHECK:       stsr ebase, r10
; CHECK:       ldsr r6, ebase
  %old = call i32 @llvm.v850.stsr(i32 35)
  call void @llvm.v850.ldsr(i32 %val, i32 35)
  ret i32 %old
}
