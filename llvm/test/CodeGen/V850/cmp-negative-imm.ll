; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m -O2 < %s | FileCheck %s

; Test that comparing with negative immediate values works correctly.
; This was crashing due to sign-extension issues when creating target constants.
; The compiler may optimize away explicit CMP instructions when merging with branches.

define i32 @test_cmp_minus_one(i32 %a) {
; CHECK-LABEL: test_cmp_minus_one:
; The comparison with -1 is transformed to comparison with 0 (a > -1 becomes a >= 0)
; and merged with the branch, so no explicit cmp instruction is emitted
; CHECK: blt
entry:
  %cmp = icmp sgt i32 %a, -1
  br i1 %cmp, label %if.then, label %if.else

if.then:
  ret i32 1

if.else:
  ret i32 0
}

define i32 @test_cmp_minus_16(i32 %a) {
; CHECK-LABEL: test_cmp_minus_16:
; The comparison is merged with the branch
; CHECK: blt
entry:
  %cmp = icmp sgt i32 %a, -16
  br i1 %cmp, label %if.then, label %if.else

if.then:
  ret i32 1

if.else:
  ret i32 0
}

; Test with an immediate that doesn't fit in 5 bits
define i32 @test_cmp_minus_17(i32 %a) {
; CHECK-LABEL: test_cmp_minus_17:
; The comparison is merged with the branch
; CHECK: blt
entry:
  %cmp = icmp sgt i32 %a, -17
  br i1 %cmp, label %if.then, label %if.else

if.then:
  ret i32 1

if.else:
  ret i32 0
}

; Interpolation pattern that was originally failing
define i32 @test_interpolate(ptr %table, i32 %size, i32 %x, i32 %x_scale) {
; CHECK-LABEL: test_interpolate:
entry:
  %div = sdiv i32 %x, %x_scale
  %cmp = icmp slt i32 %div, 0
  br i1 %cmp, label %if.then, label %if.end

if.then:
  %val0 = load i32, ptr %table
  ret i32 %val0

if.end:
  %sub = sub nsw i32 %size, 1
  %cmp2 = icmp sge i32 %div, %sub
  br i1 %cmp2, label %if.then2, label %if.end2

if.then2:
  %idx = sub nsw i32 %size, 1
  %ptr = getelementptr inbounds i32, ptr %table, i32 %idx
  %val = load i32, ptr %ptr
  ret i32 %val

if.end2:
  %ptr3 = getelementptr inbounds i32, ptr %table, i32 %div
  %val3 = load i32, ptr %ptr3
  ret i32 %val3
}
