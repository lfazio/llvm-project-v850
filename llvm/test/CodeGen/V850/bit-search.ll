; RUN: llc -mtriple=v850 -mcpu=v850e2 < %s | FileCheck %s

; Test bit search operations (ctlz/cttz) for V850E2+
; These map to SCH1L/SCH1R instructions
; V850 ctlz/cttz return 32 for zero input (defined behavior)

; Test count leading zeros - maps to SCH1L
; Note: LLVM adds zero check because is_zero_poison=false
define i32 @test_ctlz(i32 %x) {
; CHECK-LABEL: test_ctlz:
; CHECK:       sch1l r6, r10
  %result = call i32 @llvm.ctlz.i32(i32 %x, i1 false)
  ret i32 %result
}

; Test count trailing zeros - maps to SCH1R
define i32 @test_cttz(i32 %x) {
; CHECK-LABEL: test_cttz:
; CHECK:       sch1r r6, r10
  %result = call i32 @llvm.cttz.i32(i32 %x, i1 false)
  ret i32 %result
}

; Test ctlz with is_zero_poison=true (no zero check needed)
define i32 @test_ctlz_poison(i32 %x) {
; CHECK-LABEL: test_ctlz_poison:
; CHECK:       sch1l r6, r10
; CHECK-NEXT:  jmp [r31]
  %result = call i32 @llvm.ctlz.i32(i32 %x, i1 true)
  ret i32 %result
}

; Test cttz with is_zero_poison=true (no zero check needed)
define i32 @test_cttz_poison(i32 %x) {
; CHECK-LABEL: test_cttz_poison:
; CHECK:       sch1r r6, r10
; CHECK-NEXT:  jmp [r31]
  %result = call i32 @llvm.cttz.i32(i32 %x, i1 true)
  ret i32 %result
}

; Test __builtin_ffs equivalent: ffs(x) = x ? ctz(x) + 1 : 0
define i32 @test_ffs(i32 %x) {
; CHECK-LABEL: test_ffs:
; CHECK:       sch1r r6, r{{[0-9]+}}
  %ctz = call i32 @llvm.cttz.i32(i32 %x, i1 true)
  %ffs = add i32 %ctz, 1
  %cmp = icmp eq i32 %x, 0
  %result = select i1 %cmp, i32 0, i32 %ffs
  ret i32 %result
}

; Test using ctlz result in arithmetic
define i32 @test_ctlz_arithmetic(i32 %x) {
; CHECK-LABEL: test_ctlz_arithmetic:
; CHECK:       sch1l r6, r{{[0-9]+}}
  %clz = call i32 @llvm.ctlz.i32(i32 %x, i1 true)
  %result = sub i32 31, %clz
  ret i32 %result
}

declare i32 @llvm.ctlz.i32(i32, i1)
declare i32 @llvm.cttz.i32(i32, i1)
