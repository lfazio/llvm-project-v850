; RUN: llc -mtriple=v850 -mcpu=v850e2m < %s | FileCheck %s

;===----------------------------------------------------------------------===;
; Test jump table lowering using SWITCH instruction
;
; V850E1+ provides the SWITCH instruction for efficient table-driven branching.
; The instruction reads a halfword offset from a table and branches to the
; computed address.
;
; Operation:
;   adr = (PC + 2) + (index << 1)           ; Table entry address
;   PC = (PC + 2) + sign_extend(mem[adr]) << 1  ; Target address
;===----------------------------------------------------------------------===;

;===----------------------------------------------------------------------===;
; Basic switch statement test (4 cases)
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_switch_basic:
; CHECK: switch r{{[0-9]+}}
; CHECK-NEXT: .LJTI0_0:
; CHECK-NEXT: .hword
; CHECK-NEXT: .hword
; CHECK-NEXT: .hword
; CHECK-NEXT: .hword
define i32 @test_switch_basic(i32 %x) {
entry:
  switch i32 %x, label %default [
    i32 0, label %case0
    i32 1, label %case1
    i32 2, label %case2
    i32 3, label %case3
  ]

case0:
  ret i32 10

case1:
  ret i32 20

case2:
  ret i32 30

case3:
  ret i32 40

default:
  ret i32 0
}

;===----------------------------------------------------------------------===;
; Larger switch statement test (8 cases)
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_switch_large:
; CHECK: switch r{{[0-9]+}}
; CHECK-NEXT: .LJTI1_0:
; CHECK-NEXT: .hword
define i32 @test_switch_large(i32 %x) {
entry:
  switch i32 %x, label %default [
    i32 0, label %case0
    i32 1, label %case1
    i32 2, label %case2
    i32 3, label %case3
    i32 4, label %case4
    i32 5, label %case5
    i32 6, label %case6
    i32 7, label %case7
  ]

case0:
  ret i32 100
case1:
  ret i32 101
case2:
  ret i32 102
case3:
  ret i32 103
case4:
  ret i32 104
case5:
  ret i32 105
case6:
  ret i32 106
case7:
  ret i32 107
default:
  ret i32 -1
}

;===----------------------------------------------------------------------===;
; Switch with gap in cases (still uses jump table with default entries)
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_switch_sparse:
; CHECK: switch r{{[0-9]+}}
; CHECK-NEXT: .LJTI2_0:
; CHECK-NEXT: .hword
define i32 @test_switch_sparse(i32 %x) {
entry:
  switch i32 %x, label %default [
    i32 10, label %case10
    i32 20, label %case20
    i32 30, label %case30
    i32 40, label %case40
  ]

case10:
  ret i32 1
case20:
  ret i32 2
case30:
  ret i32 3
case40:
  ret i32 4
default:
  ret i32 0
}

;===----------------------------------------------------------------------===;
; Switch with function calls in cases (needs 4+ cases for jump table)
;===----------------------------------------------------------------------===;

declare void @do_case0()
declare void @do_case1()
declare void @do_case2()
declare void @do_case3()

; CHECK-LABEL: test_switch_with_calls:
; CHECK: switch r{{[0-9]+}}
; CHECK: .hword
define void @test_switch_with_calls(i32 %x) {
entry:
  switch i32 %x, label %default [
    i32 0, label %case0
    i32 1, label %case1
    i32 2, label %case2
    i32 3, label %case3
  ]

case0:
  call void @do_case0()
  br label %exit

case1:
  call void @do_case1()
  br label %exit

case2:
  call void @do_case2()
  br label %exit

case3:
  call void @do_case3()
  br label %exit

default:
  br label %exit

exit:
  ret void
}
