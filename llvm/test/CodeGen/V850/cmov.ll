; RUN: llc -march=v850 -mcpu=v850e1 < %s | FileCheck %s

; Test conditional move (CMOV) for select lowering
; CMOV instruction should be used instead of branches for select patterns

; Simple select with != 0 condition
define i32 @simple_select(i32 %cond, i32 %a, i32 %b) {
; CHECK-LABEL: simple_select:
; CHECK: cmp
; CHECK: cmov nz
; CHECK-NOT: b{{z|nz|eq|ne}}
  %c = icmp ne i32 %cond, 0
  %r = select i1 %c, i32 %a, i32 %b
  ret i32 %r
}

; Select with equality condition
define i32 @select_eq(i32 %x, i32 %y, i32 %a, i32 %b) {
; CHECK-LABEL: select_eq:
; CHECK: cmp
; CHECK: cmov z
  %c = icmp eq i32 %x, %y
  %r = select i1 %c, i32 %a, i32 %b
  ret i32 %r
}

; Select with inequality condition
define i32 @select_ne(i32 %x, i32 %y, i32 %a, i32 %b) {
; CHECK-LABEL: select_ne:
; CHECK: cmp
; CHECK: cmov nz
  %c = icmp ne i32 %x, %y
  %r = select i1 %c, i32 %a, i32 %b
  ret i32 %r
}

; Select with signed less than
define i32 @select_slt(i32 %x, i32 %y, i32 %a, i32 %b) {
; CHECK-LABEL: select_slt:
; CHECK: cmp
; CHECK: cmov lt
  %c = icmp slt i32 %x, %y
  %r = select i1 %c, i32 %a, i32 %b
  ret i32 %r
}

; Select with signed less or equal
define i32 @select_sle(i32 %x, i32 %y, i32 %a, i32 %b) {
; CHECK-LABEL: select_sle:
; CHECK: cmp
; CHECK: cmov le
  %c = icmp sle i32 %x, %y
  %r = select i1 %c, i32 %a, i32 %b
  ret i32 %r
}

; Select with signed greater than
define i32 @select_sgt(i32 %x, i32 %y, i32 %a, i32 %b) {
; CHECK-LABEL: select_sgt:
; CHECK: cmp
; CHECK: cmov gt
  %c = icmp sgt i32 %x, %y
  %r = select i1 %c, i32 %a, i32 %b
  ret i32 %r
}

; Select with signed greater or equal
define i32 @select_sge(i32 %x, i32 %y, i32 %a, i32 %b) {
; CHECK-LABEL: select_sge:
; CHECK: cmp
; CHECK: cmov ge
  %c = icmp sge i32 %x, %y
  %r = select i1 %c, i32 %a, i32 %b
  ret i32 %r
}

; Select with unsigned less than
define i32 @select_ult(i32 %x, i32 %y, i32 %a, i32 %b) {
; CHECK-LABEL: select_ult:
; CHECK: cmp
; CHECK: cmov c
  %c = icmp ult i32 %x, %y
  %r = select i1 %c, i32 %a, i32 %b
  ret i32 %r
}

; Select with unsigned less or equal
define i32 @select_ule(i32 %x, i32 %y, i32 %a, i32 %b) {
; CHECK-LABEL: select_ule:
; CHECK: cmp
; CHECK: cmov nh
  %c = icmp ule i32 %x, %y
  %r = select i1 %c, i32 %a, i32 %b
  ret i32 %r
}

; Select with unsigned greater than
define i32 @select_ugt(i32 %x, i32 %y, i32 %a, i32 %b) {
; CHECK-LABEL: select_ugt:
; CHECK: cmp
; CHECK: cmov h
  %c = icmp ugt i32 %x, %y
  %r = select i1 %c, i32 %a, i32 %b
  ret i32 %r
}

; Select with unsigned greater or equal
define i32 @select_uge(i32 %x, i32 %y, i32 %a, i32 %b) {
; CHECK-LABEL: select_uge:
; CHECK: cmp
; CHECK: cmov nc
  %c = icmp uge i32 %x, %y
  %r = select i1 %c, i32 %a, i32 %b
  ret i32 %r
}

; Test that min/max patterns also use CMOV
define i32 @min_signed(i32 %a, i32 %b) {
; CHECK-LABEL: min_signed:
; CHECK: cmp
; CHECK: cmov
  %c = icmp slt i32 %a, %b
  %r = select i1 %c, i32 %a, i32 %b
  ret i32 %r
}

define i32 @max_signed(i32 %a, i32 %b) {
; CHECK-LABEL: max_signed:
; CHECK: cmp
; CHECK: cmov
  %c = icmp sgt i32 %a, %b
  %r = select i1 %c, i32 %a, i32 %b
  ret i32 %r
}
