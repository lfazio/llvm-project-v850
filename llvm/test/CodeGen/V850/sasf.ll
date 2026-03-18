; RUN: llc -mtriple=v850 -mcpu=v850e1 < %s | FileCheck %s
; RUN: llc -mtriple=v850 -mcpu=v850e2m < %s | FileCheck %s
; RUN: llc -mtriple=v850 -mcpu=v850 < %s | FileCheck %s --check-prefix=CHECK-NOSAS

;===----------------------------------------------------------------------===;
; Test SASF (Shift and Set Flag) instruction generation
;
; SASF cccc, reg2 - shifts reg2 left by 1, sets bit 0 based on condition
; Pattern: (value << 1) | (a cmp b ? 1 : 0)
;
; SASF is available on V850ES (V850E1) and later.
;===----------------------------------------------------------------------===;

;===----------------------------------------------------------------------===;
; Basic SASF patterns - direct setcc
;===----------------------------------------------------------------------===;

; Test SASF with signed greater than (GT, condition code 15)
; CHECK-LABEL: test_sasf_gt:
; CHECK:       cmp r7, r6
; CHECK-NEXT:  sasf gt, r8
; For base V850 (no SASF), should use setf/add/or sequence
; (shl 1 is optimized to add reg, reg)
; CHECK-NOSAS-LABEL: test_sasf_gt:
; CHECK-NOSAS:       setf gt
; CHECK-NOSAS:       add r8, r8
; CHECK-NOSAS:       or
define i32 @test_sasf_gt(i32 %a, i32 %b, i32 %x) {
entry:
  %cmp = icmp sgt i32 %a, %b
  %ext = zext i1 %cmp to i32
  %shl = shl i32 %x, 1
  %or = or i32 %shl, %ext
  ret i32 %or
}

; Test SASF with signed less than (LT, condition code 6)
; CHECK-LABEL: test_sasf_lt:
; CHECK:       cmp r7, r6
; CHECK-NEXT:  sasf lt, r8
define i32 @test_sasf_lt(i32 %a, i32 %b, i32 %x) {
entry:
  %cmp = icmp slt i32 %a, %b
  %ext = zext i1 %cmp to i32
  %shl = shl i32 %x, 1
  %or = or i32 %shl, %ext
  ret i32 %or
}

; Test SASF with equal (Z, condition code 2)
; CHECK-LABEL: test_sasf_eq:
; CHECK:       cmp r7, r6
; CHECK-NEXT:  sasf z, r8
define i32 @test_sasf_eq(i32 %a, i32 %b, i32 %x) {
entry:
  %cmp = icmp eq i32 %a, %b
  %ext = zext i1 %cmp to i32
  %shl = shl i32 %x, 1
  %or = or i32 %shl, %ext
  ret i32 %or
}

; Test SASF with not equal (NZ, condition code 10)
; CHECK-LABEL: test_sasf_ne:
; CHECK:       cmp r7, r6
; CHECK-NEXT:  sasf nz, r8
define i32 @test_sasf_ne(i32 %a, i32 %b, i32 %x) {
entry:
  %cmp = icmp ne i32 %a, %b
  %ext = zext i1 %cmp to i32
  %shl = shl i32 %x, 1
  %or = or i32 %shl, %ext
  ret i32 %or
}

; Test SASF with unsigned greater than (H, condition code 11)
; CHECK-LABEL: test_sasf_ugt:
; CHECK:       cmp r7, r6
; CHECK-NEXT:  sasf h, r8
define i32 @test_sasf_ugt(i32 %a, i32 %b, i32 %x) {
entry:
  %cmp = icmp ugt i32 %a, %b
  %ext = zext i1 %cmp to i32
  %shl = shl i32 %x, 1
  %or = or i32 %shl, %ext
  ret i32 %or
}

; Test SASF with unsigned less than (C/L, condition code 1)
; CHECK-LABEL: test_sasf_ult:
; CHECK:       cmp r7, r6
; CHECK-NEXT:  sasf c, r8
define i32 @test_sasf_ult(i32 %a, i32 %b, i32 %x) {
entry:
  %cmp = icmp ult i32 %a, %b
  %ext = zext i1 %cmp to i32
  %shl = shl i32 %x, 1
  %or = or i32 %shl, %ext
  ret i32 %or
}

; Test SASF with signed less than or equal (LE, condition code 7)
; CHECK-LABEL: test_sasf_le:
; CHECK:       cmp r7, r6
; CHECK-NEXT:  sasf le, r8
define i32 @test_sasf_le(i32 %a, i32 %b, i32 %x) {
entry:
  %cmp = icmp sle i32 %a, %b
  %ext = zext i1 %cmp to i32
  %shl = shl i32 %x, 1
  %or = or i32 %shl, %ext
  ret i32 %or
}

; Test SASF with signed greater than or equal (GE, condition code 14)
; CHECK-LABEL: test_sasf_ge:
; CHECK:       cmp r7, r6
; CHECK-NEXT:  sasf ge, r8
define i32 @test_sasf_ge(i32 %a, i32 %b, i32 %x) {
entry:
  %cmp = icmp sge i32 %a, %b
  %ext = zext i1 %cmp to i32
  %shl = shl i32 %x, 1
  %or = or i32 %shl, %ext
  ret i32 %or
}

;===----------------------------------------------------------------------===;
; Alternative pattern: shift on RHS of OR
;===----------------------------------------------------------------------===;

; Test SASF with shift on RHS: (cond | (x << 1))
; CHECK-LABEL: test_sasf_reverse:
; CHECK:       cmp r7, r6
; CHECK-NEXT:  sasf gt, r8
define i32 @test_sasf_reverse(i32 %a, i32 %b, i32 %x) {
entry:
  %cmp = icmp sgt i32 %a, %b
  %ext = zext i1 %cmp to i32
  %shl = shl i32 %x, 1
  %or = or i32 %ext, %shl
  ret i32 %or
}

;===----------------------------------------------------------------------===;
; Test (and (setcc ...), 1) pattern
;===----------------------------------------------------------------------===;

; Test SASF with explicit AND masking of comparison result
; CHECK-LABEL: test_sasf_and_mask:
; CHECK:       cmp r7, r6
; CHECK-NEXT:  sasf gt, r8
define i32 @test_sasf_and_mask(i32 %a, i32 %b, i32 %x) {
entry:
  %cmp = icmp sgt i32 %a, %b
  %ext = zext i1 %cmp to i32
  %masked = and i32 %ext, 1
  %shl = shl i32 %x, 1
  %or = or i32 %shl, %masked
  ret i32 %or
}

;===----------------------------------------------------------------------===;
; Negative tests - patterns that should NOT generate SASF
;===----------------------------------------------------------------------===;

; Should NOT generate SASF when shift amount is not 1
; CHECK-LABEL: test_no_sasf_shift2:
; CHECK:       setf gt
; CHECK:       shl 2
; CHECK:       or
; CHECK-NOT:   sasf gt
define i32 @test_no_sasf_shift2(i32 %a, i32 %b, i32 %x) {
entry:
  %cmp = icmp sgt i32 %a, %b
  %ext = zext i1 %cmp to i32
  %shl = shl i32 %x, 2
  %or = or i32 %shl, %ext
  ret i32 %or
}

;===----------------------------------------------------------------------===;
; Practical use cases
;===----------------------------------------------------------------------===;

; Building a bit vector from comparisons - shows SASF in chain
; CHECK-LABEL: test_bitvector:
; CHECK:       sasf lt, r10
define i32 @test_bitvector(i32 %a, i32 %b) {
entry:
  %cmp1 = icmp sgt i32 %a, %b
  %ext1 = zext i1 %cmp1 to i32
  %shl = shl i32 %ext1, 1
  %cmp2 = icmp slt i32 %a, %b
  %ext2 = zext i1 %cmp2 to i32
  %or = or i32 %shl, %ext2
  ret i32 %or
}
