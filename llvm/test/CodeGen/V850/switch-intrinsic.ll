; RUN: llc -mtriple=v850 -mcpu=v850e1 < %s | FileCheck %s

;===----------------------------------------------------------------------===;
; Test SWITCH intrinsic (table-driven branch)
;
; The V850E1+ SWITCH instruction provides efficient table-driven branching.
; It reads a halfword offset from a table immediately following the
; instruction and branches to the computed target address.
;
; Operation:
;   adr = (PC + 2) + (index << 1)           ; Table entry address
;   PC = (PC + 2) + sign_extend(mem[adr]) << 1  ; Target address
;
; Note: The table must be placed immediately after the SWITCH instruction
; by the programmer/compiler when using inline assembly or intrinsics.
;===----------------------------------------------------------------------===;

declare void @llvm.v850.switch(i32)

;===----------------------------------------------------------------------===;
; Basic SWITCH intrinsic test
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_switch_basic:
; CHECK: switch r{{[0-9]+}}
define void @test_switch_basic(i32 %index) {
entry:
  call void @llvm.v850.switch(i32 %index)
  ret void
}

;===----------------------------------------------------------------------===;
; SWITCH with index from memory
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_switch_from_memory:
; CHECK: ld.w
; CHECK: switch r{{[0-9]+}}
define void @test_switch_from_memory(ptr %index_ptr) {
entry:
  %index = load i32, ptr %index_ptr
  call void @llvm.v850.switch(i32 %index)
  ret void
}

;===----------------------------------------------------------------------===;
; SWITCH with computed index
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_switch_computed:
; CHECK: add
; CHECK: switch r{{[0-9]+}}
define void @test_switch_computed(i32 %base, i32 %offset) {
entry:
  %index = add i32 %base, %offset
  call void @llvm.v850.switch(i32 %index)
  ret void
}

;===----------------------------------------------------------------------===;
; SWITCH with masked index (bounds check pattern)
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_switch_masked:
; CHECK: and
; CHECK: switch r{{[0-9]+}}
define void @test_switch_masked(i32 %raw_index) {
entry:
  ; Mask to ensure index is in range 0-7
  %index = and i32 %raw_index, 7
  call void @llvm.v850.switch(i32 %index)
  ret void
}
