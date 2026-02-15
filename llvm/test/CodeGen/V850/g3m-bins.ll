; RUN: llc -mtriple=v850-unknown-elf -mcpu=g3m -O2 < %s | FileCheck %s

; Test BINS (bitfield insert) instruction generation for RH850G3M.
; BINS inserts 'width' bits from src at position 'pos' into dst.
; Three encoding variants selected by msb/lsb ranges:
;   BINS0: msb >= 16 AND lsb >= 16
;   BINS1: msb >= 16 AND lsb < 16
;   BINS2: msb < 16  AND lsb < 16

declare i32 @llvm.v850.bins(i32, i32, i32, i32)

; --- BINS2: msb < 16, lsb < 16 ---

define i32 @test_bins2_byte_low(i32 %dst, i32 %src) {
; CHECK-LABEL: test_bins2_byte_low:
; CHECK:       bins r7, 0, 7, r6
  %r = call i32 @llvm.v850.bins(i32 %dst, i32 %src, i32 0, i32 8)
  ret i32 %r
}

define i32 @test_bins2_nibble(i32 %dst, i32 %src) {
; CHECK-LABEL: test_bins2_nibble:
; CHECK:       bins r7, 4, 7, r6
  %r = call i32 @llvm.v850.bins(i32 %dst, i32 %src, i32 4, i32 4)
  ret i32 %r
}

define i32 @test_bins2_single_bit(i32 %dst, i32 %src) {
; CHECK-LABEL: test_bins2_single_bit:
; CHECK:       bins r7, 15, 15, r6
  %r = call i32 @llvm.v850.bins(i32 %dst, i32 %src, i32 15, i32 1)
  ret i32 %r
}

; --- BINS1: msb >= 16, lsb < 16 ---

define i32 @test_bins1_cross(i32 %dst, i32 %src) {
; CHECK-LABEL: test_bins1_cross:
; CHECK:       bins r7, 12, 19, r6
  %r = call i32 @llvm.v850.bins(i32 %dst, i32 %src, i32 12, i32 8)
  ret i32 %r
}

define i32 @test_bins1_wide(i32 %dst, i32 %src) {
; CHECK-LABEL: test_bins1_wide:
; CHECK:       bins r7, 0, 31, r6
  %r = call i32 @llvm.v850.bins(i32 %dst, i32 %src, i32 0, i32 32)
  ret i32 %r
}

; --- BINS0: msb >= 16, lsb >= 16 ---

define i32 @test_bins0_byte_high(i32 %dst, i32 %src) {
; CHECK-LABEL: test_bins0_byte_high:
; CHECK:       bins r7, 16, 23, r6
  %r = call i32 @llvm.v850.bins(i32 %dst, i32 %src, i32 16, i32 8)
  ret i32 %r
}

define i32 @test_bins0_top_byte(i32 %dst, i32 %src) {
; CHECK-LABEL: test_bins0_top_byte:
; CHECK:       bins r7, 24, 31, r6
  %r = call i32 @llvm.v850.bins(i32 %dst, i32 %src, i32 24, i32 8)
  ret i32 %r
}
