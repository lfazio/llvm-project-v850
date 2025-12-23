; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test basic arithmetic operations

; CHECK-LABEL: test_add:
; CHECK: mov r6, r10
; CHECK: add r7, r10
; CHECK: jmp [lp]
define i32 @test_add(i32 %a, i32 %b) {
  %sum = add i32 %a, %b
  ret i32 %sum
}

; CHECK-LABEL: test_sub:
; CHECK: mov r6, r10
; CHECK: sub r7, r10
; CHECK: jmp [lp]
define i32 @test_sub(i32 %a, i32 %b) {
  %diff = sub i32 %a, %b
  ret i32 %diff
}

; CHECK-LABEL: test_and:
; CHECK: mov r6, r10
; CHECK: and r7, r10
; CHECK: jmp [lp]
define i32 @test_and(i32 %a, i32 %b) {
  %result = and i32 %a, %b
  ret i32 %result
}

; CHECK-LABEL: test_or:
; CHECK: mov r6, r10
; CHECK: or r7, r10
; CHECK: jmp [lp]
define i32 @test_or(i32 %a, i32 %b) {
  %result = or i32 %a, %b
  ret i32 %result
}

; CHECK-LABEL: test_xor:
; CHECK: mov r6, r10
; CHECK: xor r7, r10
; CHECK: jmp [lp]
define i32 @test_xor(i32 %a, i32 %b) {
  %result = xor i32 %a, %b
  ret i32 %result
}

; CHECK-LABEL: test_not:
; CHECK: not r6, r10
; CHECK: jmp [lp]
define i32 @test_not(i32 %a) {
  %result = xor i32 %a, -1
  ret i32 %result
}
