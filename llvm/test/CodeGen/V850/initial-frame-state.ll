; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m -filetype=obj < %s -o %t.o
; RUN: llvm-readelf --sections %t.o | FileCheck %s --check-prefix=CHECK-SECTION
; RUN: llvm-objdump -s -j .eh_frame %t.o | FileCheck %s --check-prefix=CHECK-EH

; Test that the initial frame state is correctly configured for V850.
; The CIE (Common Information Entry) in .eh_frame should contain:
;   CFA = SP + 0 (DW_CFA_def_cfa r3, 0)
;
; This is configured in V850MCTargetDesc.cpp via addInitialFrameState().

; CHECK-SECTION: .eh_frame

; Check the .eh_frame section contains DW_CFA_def_cfa for r3 (SP) with offset 0
; The encoding is: 0x0c 0x03 0x00 (DW_CFA_def_cfa, reg3, 0)
; CHECK-EH: .eh_frame:
; CHECK-EH: 0c0300

define i32 @simple(i32 %a, i32 %b) {
  %sum = add i32 %a, %b
  ret i32 %sum
}
