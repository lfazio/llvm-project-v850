; RUN: llc -mtriple=v850 -mcpu=v850e1 < %s | FileCheck %s

; Test byte swap operations for V850E1+
; BSW: Full 32-bit byte reversal (bswap32)
; BSH: Byte swap in lower halfword
; HSW: Halfword swap (rotate by 16)

; Test bswap32 - maps to BSW
define i32 @test_bswap32(i32 %x) {
; CHECK-LABEL: test_bswap32:
; CHECK:       bsw r6, r10
; CHECK-NEXT:  jmp [r31]
  %result = call i32 @llvm.bswap.i32(i32 %x)
  ret i32 %result
}

; Test halfword swap pattern (x >> 16) | (x << 16) - maps to HSW
define i32 @test_hsw_pattern1(i32 %x) {
; CHECK-LABEL: test_hsw_pattern1:
; CHECK:       hsw r6, r10
; CHECK-NEXT:  jmp [r31]
  %hi = lshr i32 %x, 16
  %lo = shl i32 %x, 16
  %result = or i32 %hi, %lo
  ret i32 %result
}

; Test halfword swap pattern (x << 16) | (x >> 16) - maps to HSW
define i32 @test_hsw_pattern2(i32 %x) {
; CHECK-LABEL: test_hsw_pattern2:
; CHECK:       hsw r6, r10
; CHECK-NEXT:  jmp [r31]
  %lo = shl i32 %x, 16
  %hi = lshr i32 %x, 16
  %result = or i32 %lo, %hi
  ret i32 %result
}

; Test HSW intrinsic
define i32 @test_hsw_intrinsic(i32 %x) {
; CHECK-LABEL: test_hsw_intrinsic:
; CHECK:       hsw r6, r10
; CHECK-NEXT:  jmp [r31]
  %result = call i32 @llvm.v850.hsw(i32 %x)
  ret i32 %result
}

; Test BSH intrinsic
define i32 @test_bsh_intrinsic(i32 %x) {
; CHECK-LABEL: test_bsh_intrinsic:
; CHECK:       bsh r6, r10
; CHECK-NEXT:  jmp [r31]
  %result = call i32 @llvm.v850.bsh(i32 %x)
  ret i32 %result
}

; Test bswap16 - uses bsw + shr 16
define i32 @test_bswap16_zext(i32 %x) {
; CHECK-LABEL: test_bswap16_zext:
; CHECK:       bsw r6, r{{[0-9]+}}
; CHECK:       shr 16, r{{[0-9]+}}
  %masked = and i32 %x, 65535
  %swapped = call i32 @llvm.bswap.i32(i32 %masked)
  %result = lshr i32 %swapped, 16
  ret i32 %result
}

; Test actual i16 bswap
define i16 @test_bswap16(i16 %x) {
; CHECK-LABEL: test_bswap16:
; CHECK:       bsw r6, r{{[0-9]+}}
; CHECK:       shr 16, r{{[0-9]+}}
  %result = call i16 @llvm.bswap.i16(i16 %x)
  ret i16 %result
}

declare i32 @llvm.bswap.i32(i32)
declare i16 @llvm.bswap.i16(i16)
declare i32 @llvm.v850.hsw(i32)
declare i32 @llvm.v850.bsh(i32)
